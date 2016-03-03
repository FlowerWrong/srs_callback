require 'redis'
require 'open3'
require 'json'

redis = Redis.new
# redis.lpush
threads = []

loop do
  job = redis.rpop('ffmpeg_job_queue')
  continue if job.nil?
  thr = Thread.new {
    Open3.popen3(job) {|stdin, stdout, stderr, wait_thr|
      pid = wait_thr.pid # pid of the started process.
      redis.lpush('ffmpeg_jobing_queue', {pid: pid, cmd: job}.to_json)
      exit_status = wait_thr.value # Process::Status object returned.
    }
  }
  threads << {thread: thr, pid: @pid}
end
