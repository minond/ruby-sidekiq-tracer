require "spec_helper"

RSpec.describe ::Sidekiq::Tracer::ServerMiddleware do
  let(:tracer) { ::OpenTracingTestTracer.build }

  before do
    ::OpenTracing.global_tracer = tracer
    ::Sidekiq::Tracer.instrument_server
  end

  after do
    ::Sidekiq::Tracer.uninstrument_server
  end

  describe "auto-instrumentation" do
    before do
      TestWorker.schedule_test_job
      TestWorker.drain
    end

    it "creates a new span" do
      expect(tracer.spans).to_not be_empty
    end

    it "sets operation_name to job name" do
      expect(tracer.spans.first.operation_name).to eq "Worker TestWorker"
    end

    it "sets standard OT tags" do
      [
        ['component', 'Sidekiq'],
        ['span.kind', 'server']
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

  describe "client-server trace context propagation" do
    before do
      ::Sidekiq::Tracer.instrument
      ::OpenTracing.start_active_span("root") do
        TestWorker.schedule_test_job
      end
      TestWorker.drain
    end

    after do
      ::Sidekiq::Tracer.uninstrument_client
    end

    it "creates spans for each part of the chain" do
      expect(tracer.spans.size).to be 3
    end

    it "all spans contains the same trace_id" do
      root_span = tracer.spans[0].context
      client_span = tracer.spans[1].context
      server_span = tracer.spans[2].context

      expect(root_span.span_id).to eq client_span.parent_id
      expect(client_span.span_id).to eq server_span.parent_id
    end
  end
end
