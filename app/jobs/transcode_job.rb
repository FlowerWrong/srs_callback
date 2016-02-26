class TranscodeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # transcode_stream = args[0]
    input_rtmp = args[1] # rtmp://192.168.10.160/live/demo
    output_rtmp = args[2] # rtmp://192.168.10.160/live?token=11111111111111111111111111111111/livestream

    ffmpeg = `which ffmpeg`.strip

    cmd = %W(#{ffmpeg} -i #{input_rtmp} -vcodec copy -acodec copy -f flv -y #{output_rtmp})
    # cmd.concat(other_options.split(" "))
    cmd.reject!(&:empty?)

    system(*cmd)
  end
end
