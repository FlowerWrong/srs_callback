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
    Dir.foreach("#{hls_dir}/#{app_name}") do |file|
      next if file == '.' || file == '..'
      reg_html = /.*\.html/
      reg_m3u8 = /#{stream_name}(_\d+p)?\.m3u8/
      reg_ts = /#{stream_name}(_\d+p)?\-\d+\.ts/
      reg_tmp = /#{stream_name}(_\d+p)?\-\d+\.ts\.tmp/

      if reg_html =~ file || reg_m3u8 =~ file || reg_ts =~ file || reg_tmp =~ file
        Rails.logger.info "Got file #{file} to be delete of #{app_name}/#{stream_name} in #{hls_dir}"
        FileUtils.rm "#{hls_dir}/#{app_name}/#{file}"
      end
    end
  end
end
