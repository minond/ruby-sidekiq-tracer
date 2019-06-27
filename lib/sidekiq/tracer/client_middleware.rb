module Sidekiq
  module Tracer
    class ClientMiddleware
      include Commons

      def call(worker_class, job, queue, redis_pool)
        parent_span = extract(job) || ::OpenTracing.active_span
        span = ::OpenTracing.start_span(operation_name(job),
                                        child_of: parent_span,
                                        tags: tags(job, 'client'))

        inject(span, job)

        yield
      rescue Exception => e
        if span
          span.set_tag('error', true)
          span.log(event: 'error', :'error.object' => e)
        end
        raise
      ensure
        span.finish if span
      end

      private

      def inject(span, job)
        carrier = {}
        ::OpenTracing.inject(span.context, OpenTracing::FORMAT_TEXT_MAP, carrier)
        job[TRACE_CONTEXT_KEY] = carrier
      end
    end
  end
end
