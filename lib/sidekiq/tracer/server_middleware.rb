module Sidekiq
  module Tracer
    class ServerMiddleware
      include Commons

      attr_reader :tracer, :active_span

      def initialize(tracer:, active_span:)
        @tracer = tracer
        @active_span = active_span
      end

      def call(worker, job, queue)
        parent_span_context = extract(job)

        scope = tracer.start_active_span("Worker " + operation_name(job),
                                         child_of: parent_span_context,
                                         tags: tags(job, 'server'))
        span = scope.span if scope

        yield
      rescue Exception => e
        if span
          span.set_tag('error', true)
          span.log(event: 'error', :'error.object' => e)
        end
        raise
      ensure
        scope.close if scope
      end

      private

      def extract(job)
        carrier = job[TRACE_CONTEXT_KEY]
        return unless carrier

        tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)
      end
    end
  end
end
