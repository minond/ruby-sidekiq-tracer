module Sidekiq
  module Tracer
    module Commons
      def operation_name(job)
        "Worker " + job['class']
      end

      def tags(job, kind)
        {
          'component' => 'Sidekiq',
          'span.kind' => kind,
          'sidekiq.queue' => job['queue'],
          'sidekiq.jid' => job['jid'],
          'sidekiq.retry' => job['retry'].to_s,
          'sidekiq.args' => job['args'].join(", ")
        }
      end

      def extract(job)
        carrier = job[TRACE_CONTEXT_KEY]
        return unless carrier

        tracer.extract(OpenTracing::FORMAT_TEXT_MAP, carrier)
      end
    end
  end
end
