require 'redis'

redis = Redis.new
# redis.lpush
threads = []

loop do
  job = redis.rpop('ffmpeg_job_queue')
  continue if job.nil?
  thr = Thread.new {
    msg = `#{job}`
  }
  threads << thr
end

