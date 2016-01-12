ns_redis = proc {
  redis_connection = Redis.new(driver: :hiredis)
  Redis::Namespace.new(:srs, redis: redis_connection)
}
Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 5, &ns_redis)
end
Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 25, &ns_redis)
end
