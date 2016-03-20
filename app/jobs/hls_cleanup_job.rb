require 'fileutils'

class HlsCleanupJob < ApplicationJob
  queue_as :default

  def perform(*args)
    app_name = args[0]
    stream_name = args[1]
    hls_dir = Settings.hls_dir
    # livestream-0.ts
    # livestream_240p-1.ts.tmp
    # livestream_240p.m3u8
    # FileUtils.rm Dir.glob('*.html')
    # FileUtils.rm Dir.glob(/#{stream_name}\.m3u8/)
    # FileUtils.rm Dir.glob(/#{stream_name}\-\d+\.ts/)
    # FileUtils.rm Dir.glob(/#{stream_name}\-\d+\.ts\.tmp/)
    #
    # FileUtils.rm Dir.glob(/#{stream_name}_\d+p\.m3u8/)
    # FileUtils.rm Dir.glob(/#{stream_name}_\d+p\-\d+\.ts/)
    # FileUtils.rm Dir.glob(/#{stream_name}_\d+p\-\d+\.ts\.tmp/)
    Dir.foreach("#{hls_dir}/#{app_name}") do |file|
      next if file == '.' || file == '..'
      reg_html = /.*\.html/
      if reg_html =~ file
        puts "Got html #{file}"
        # File.delete file
      end
      reg_m3u8 = /#{stream_name}\.m3u8/
    end
  end
end
