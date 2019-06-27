class TestWorker
  include ::Sidekiq::Worker

  def perform(*args)
  end

  def self.schedule_test_job
    TestWorker.perform_async("value1", "value2", 1)
  end
end
