class ScaleTranscodeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    live_client_id = args[0]
    pa = args[1]
    scale_transcodes(live_client_id, pa)
  end

  private

  def scale_transcodes(live_client_id, pa)
    if pa['action'] == 'on_publish'
      # NOTE if sleep time is too short, video and audio may be null("video":null,"audio":null), so retry untill video and audio not null
      res_json_str = nil
      res_hash = nil
      sleep_time = 0.5
      # 请求直播流的累积时间
      spent_time = 0.00
      # 请求直播流的累积次数
      spent_number_of_times = 0
      begin
        sleep sleep_time
        spent_time += sleep_time
        spent_number_of_times += 1

        res_json_str = ::RestClient.get("#{Settings.rtmp_api}/streams/")
        Rails.logger.info("srs server response streams str is #{res_json_str}")
        Rails.logger.info("pa is #{pa}")

        res_hash = JSON.parse(res_json_str)
        has_live_stream = false
        # FIXME flash media live encoder bug: audio for mp3 is null
        res_hash['streams'].each do |stream|
          has_live_stream = true if stream['name'] == pa['stream'] && stream['app'] = pa['app'] && stream['publish']['active'] && !stream['video'].nil? # && !stream['audio'].nil?
        end
        unless has_live_stream
          raise LiveStreamNotFoundException
        end
      rescue
         retry if spent_number_of_times < 10
      end
      return if res_json_str.nil? || res_hash.nil?
      Rails.logger.info("Total spent #{spent_time}s to get srs server publish stream.")
      Rails.logger.info("Total spent #{spent_number_of_times} number of times to get srs server publish stream.")

      res_hash['streams'].each do |stream|
        if stream['name'] == pa['stream'] && stream['app'] = pa['app'] && stream['publish']['active']
          Rails.logger.info "json parsed stream is #{stream}"
          next if stream['video'].nil? || stream['audio'].nil?

          video_data_rate = stream['video']['video_data_rate']
          audio_data_rate = stream['audio']['audio_data_rate']
          bit_rate = video_data_rate.to_i + audio_data_rate.to_i

          stream_name = pa['stream']
          Rails.logger.info("#{stream_name}'s bit rate is #{bit_rate}")
          transcodes = []
          input_rtmp = "#{pa['tcUrl']}/#{stream_name}"

          origin_stream_name = STREAM_REG =~ stream_name ? $1 : stream_name
          output_rtmp_prefix = "#{pa['tcUrl']}/#{origin_stream_name}"

          # @see https://support.google.com/youtube/answer/2853702?hl=zh-Hans
          case bit_rate
          when 6000..10000 # 1080p@60fps -> 720p, 480p, 360p
            ['720p'].each do |transcode_stream|
              transcodes << transcode_stream
            end
          when 4000..6000 # 1080p -> 720p, 480p, 360p
            ['720p'].each do |transcode_stream|
              transcodes << transcode_stream
            end
          when 2500..4000 # 720p@60fps -> 480p, 360p
            ['480p'].each do |transcode_stream|
              transcodes << transcode_stream
            end
          when 1500..2500 # 720p -> 480p, 360p
            ['480p'].each do |transcode_stream|
              transcodes << transcode_stream
            end
          # when 1000..1500 # 480p -> 360p
          # ...
          when 600..1500 # 360p
            ['240p'].each do |transcode_stream|
              transcodes << transcode_stream
            end
          when 0..600 # 240p
          end

          Rails.logger.info "scaled transcodes are #{transcodes.join(', ')}"

          transcodes.each do |ts|
            transcode = Transcode.create(
              live_client_id: live_client_id,
              input_rtmp: input_rtmp,
              output_rtmp: "#{output_rtmp_prefix}_#{ts}",
              ip: pa['ip'],
              vhost: pa['vhost'],
              app: pa['app'],
              stream: "#{origin_stream_name}_#{ts}",
              status: 1
            )
            # TranscodeJobWithoutSidekiq.perform(ts, input_rtmp, "#{output_rtmp_prefix}_#{ts}", transcode.id)
            TranscodeJob.perform_later(ts, input_rtmp, "#{output_rtmp_prefix}_#{ts}", transcode.id)
            Rails.logger.info("TranscodeJobWithoutSidekiq performed for #{input_rtmp}")
          end
        end
      end unless res_hash['streams'].blank?
    end
  end
end
