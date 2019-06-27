require "sidekiq"

require "sidekiq/tracer/version"
require "sidekiq/tracer/constants"
require "sidekiq/tracer/commons"
require "sidekiq/tracer/client_middleware"
require "sidekiq/tracer/server_middleware"

module Sidekiq
  module Tracer
    class << self
      def instrument
        instrument_client
        instrument_server
      end

      def instrument_client
        configure_client :add
      end

      def instrument_server
        configure_server :add
      end

      def uninstrument_client
        configure_client :remove
      end

      def uninstrument_server
        configure_server :remove
      end

      def configure_client(method)
        ::Sidekiq.configure_client do |config|
          config.client_middleware do |chain|
            chain.public_send(method, Sidekiq::Tracer::ClientMiddleware)
          end
        end
      end

      def configure_server(method)
        ::Sidekiq.configure_server do |config|
          config.client_middleware do |chain|
            chain.public_send(method, Sidekiq::Tracer::ClientMiddleware)
          end

          config.server_middleware do |chain|
            chain.public_send(method, Sidekiq::Tracer::ServerMiddleware)
          end
        end

        if defined?(Sidekiq::Testing)
          ::Sidekiq::Testing.server_middleware do |chain|
            chain.public_send(method, Sidekiq::Tracer::ServerMiddleware)
          end
        end
      end
    end
  end
end
