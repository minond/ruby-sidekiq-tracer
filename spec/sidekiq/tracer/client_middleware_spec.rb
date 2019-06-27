require "spec_helper"

RSpec.describe ::Sidekiq::Tracer::ClientMiddleware do
  let(:tracer) { ::OpenTracingTestTracer.build }

  before do
    ::OpenTracing.global_tracer = tracer
    ::Sidekiq::Tracer.instrument_client
  end

  after do
    ::Sidekiq::Tracer.uninstrument_client
  end

  describe "pushing to the queue" do
    before { TestWorker.schedule_test_job }

    it "still enqueues job to the queue" do
      expect(TestWorker.jobs.size).to eq(1)
    end
  end

  describe "auto-instrumentation" do
    before { TestWorker.schedule_test_job }

    it "creates a new span" do
      expect(tracer.spans).to_not be_empty
    end

    it "sets operation_name to job name" do
      expect(tracer.spans.first.operation_name).to eq "Worker TestWorker"
    end

    it "sets standard OT tags" do
      [
        ['component', 'Sidekiq'],
        ['span.kind', 'client']
      ].each do |key, value|
        expect(tracer.spans.first.tags).to include(key => value)
      end
    end

    it "sets Sidekiq specific OT tags" do
      [
        ['sidekiq.queue', 'default'],
        ['sidekiq.retry', "true"],
        ['sidekiq.args', "value1, value2, 1"],
        ['sidekiq.jid', /\S+/]
      ].each do |key, value|
        expect(tracer.spans.first.tags).to include(key => value)
      end
    end
  end

  describe "active span propagation" do
    before do
      ::OpenTracing.start_active_span("root") do
        TestWorker.schedule_test_job
      end
    end

    it "creates the new span with active span trace_id" do
      expect(tracer.spans.size).to be 2
    end

    it "creates the new span with active span as a parent" do
      expect(tracer.spans[1].context.parent_id).to eq tracer.spans.first.context.span_id
    end
  end

  describe "span context injection" do
    before { TestWorker.schedule_test_job }

    it "injects span context to enqueued job" do
      carrier = TestWorker.jobs.last[::Sidekiq::Tracer::TRACE_CONTEXT_KEY]
      job_context = ::OpenTracing.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)
      expect(job_context.span_id).to eq tracer.spans.first.context.span_id
    end
  end
end
