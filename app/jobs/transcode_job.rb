class TranscodeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    transcode_stream = args[0]
    input_rtmp = args[1] # rtmp://192.168.10.160/live/demo
    output_rtmp = args[2] # rtmp://192.168.10.160/live?token=11111111111111111111111111111111/livestream

    # @see https://github.com/ossrs/srs/wiki/v2_CN_FFMPEG#transcode-rulers
    # FIXME Unknown encoder 'libx264'
    ffmpeg_opts = "-vcodec libx264 -b:v #{bitrate2resolution[transcode_stream][:bitrate]} -r 30 -s #{bitrate2resolution[transcode_stream][:width]}x#{bitrate2resolution[transcode_stream][:height]} -aspect #{bitrate2resolution[transcode_stream][:width]}:#{bitrate2resolution[transcode_stream][:height]} -threads 8 -acodec libfdk_aac -b:a 128000 -ar 44100  -ac 2"

    ffmpeg = `which ffmpeg`.strip

    cmd = %W(#{ffmpeg} -v quiet -i #{input_rtmp} #{ffmpeg_opts} -f flv -y #{output_rtmp})
    # cmd.concat(other_options.split(" "))
    Rails.logger.info cmd
    cmd.reject!(&:empty?)

    system(cmd.join(' '))
  end

  private

  def bitrate2resolution
    {
      '720p' => {width: 1280, height: 720, bitrate: 2500000},
      '480p' => {width: 854, height: 480, bitrate: 1000000},
      '360p' => {width: 640, height: 360, bitrate: 750000},
      '240p' => {width: 426, height: 240, bitrate: 400000}
    }
  end
end
