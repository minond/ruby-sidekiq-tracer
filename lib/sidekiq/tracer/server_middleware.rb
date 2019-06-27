module Sidekiq
  module Tracer
    class ServerMiddleware
      include Commons

      def call(worker, job, queue)
        parent_span = extract(job) || ::OpenTracing.active_span
        scope = ::OpenTracing.start_active_span(operation_name(job),
                                                child_of: parent_span,
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
    end
  end
end
