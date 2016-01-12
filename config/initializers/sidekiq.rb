ns_redis = proc {
  redis_connection = Redis.new(driver: :hiredis)
  Redis::Namespace.new(:srs, redis: redis_connection)
}
Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 5, &ns_redis)

  config.client_middleware do |chain|
    # accepts :expiration (optional)
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 30.minutes
  end
end
Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 25, &ns_redis)

  config.server_middleware do |chain|
    # accepts :expiration (optional)
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes # default
  end
  config.client_middleware do |chain|
    # accepts :expiration (optional)
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 30.minutes # default
  end
end
