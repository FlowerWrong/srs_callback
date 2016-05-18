require 'json'
require 'rest-client'

class LiveStreamNotFoundException < StandardError
  def initialize(msg = 'live stream not found in srs server response json string')
    super(msg)
  end
end

class Api::V1::SrsController < ApplicationController
  # @see https://github.com/ossrs/srs/wiki/v2_CN_HTTPCallback#http-callback-events

  STREAM_REG = /^([a-z|A-Z]+)_\d+p/ # livestream_420p

  # on_connect
  # on_close
  def clients
    render plain: '0', status: :ok
  end

  # on_publish
  # on_unpublish
  def streams
    pa = request.request_parameters
    @lc = nil
    if pa['action'] == 'on_publish'
      Rails.logger.info("Rails on_publish params are #{pa}")
      white_ips = Settings.white_ip_list.split(' ')
      client_ip = pa['ip']
      # 先验证白名单
      unless white_ips.include? client_ip
        # 再验证token
        white_tokens = Settings.token_list.split(' ')
        client_token = pa['tcUrl'].last(32)
        unless white_tokens.include? client_token
          render(plain: 'auth failed', status: 401) && return
        end
      end

      stream_name = pa['stream']
      # 说明是转码的
      if STREAM_REG =~ stream_name
        live_clients = LiveClient.where(vhost: pa['vhost'], app: pa['app'], stream: $1, status: 1)
        Rails.logger.info "live_clients count are #{live_clients.size}"
        @lc = live_clients.last
      else
        # 转码
        live_transcodes = Transcode.where(ip: pa['ip'], vhost: pa['vhost'], app: pa['app'], stream: pa['stream'], status: 1)
        Rails.logger.info "live_transcodes count are #{live_transcodes.size}"
        if live_transcodes.blank?
          live_clients = LiveClient.where(client_id: pa['client_id'], ip: pa['ip'], vhost: pa['vhost'], app: pa['app'], stream: pa['stream'], status: 1)
          Rails.logger.info "live_clients count are #{live_clients.size}"
          if live_clients.blank?
            @lc = LiveClient.create(
              client_id: pa['client_id'],
              ip: pa['ip'],
              vhost: pa['vhost'],
              app: pa['app'],
              stream: pa['stream'],
              tc_url: pa['tcUrl'],
              status: 1
            )
          end
        end
      end
    elsif pa['action'] == 'on_unpublish'
      live_clients = LiveClient.where(client_id: pa['client_id'], ip: pa['ip'], vhost: pa['vhost'], app: pa['app'], stream: pa['stream'], status: 1)
      if live_clients.blank?
        @live_transcodes = Transcode.where(ip: pa['ip'], vhost: pa['vhost'], app: pa['app'], stream: pa['stream'], status: 1)
      else
        @live_transcodes = []
        live_clients.each do |lc|
          lc.transcodes.each do |lt|
            @live_transcodes << lt
          end
        end
      end

      # 先取消所有转码
      @live_transcodes.each do |lt|
        Process.kill('KILL', lt.pid)
        lt.update(status: 0)
        # FIXME
        `killall -KILL ffmpeg` # kill all ffmpeg, there is a bug with sh -c
      end unless @live_transcodes.blank?
      # 再标记直播流
      live_clients.each { |lc| lc.update(status: 0) }
      # 清楚所有的hls缓存
      HlsCleanupJob.perform_later(pa['app'], pa['stream'])
    else
      render(plain: 'auth failed', status: 401) && return
    end

    render plain: '0', status: :ok

    # FIXME bug when puma
    Thread.new do
      scale_transcodes(@lc.id, pa)
      Rails.logger.info "on_publish thread status is #{Thread.current.status}"
      Thread.current.exit
      Rails.logger.info "on_publish thread after exit status is #{Thread.current.status}"
    end if pa['action'] == 'on_publish' && !@lc.nil?
  end

  # on_play
  # on_stop
  def sessions
    pa = request.request_parameters
    if pa['action'] == 'on_play'
      clients = Session.where(client_id: pa['client_id'], ip: pa['ip'], vhost: pa['vhost'], app: pa['app'], stream: pa['stream'], status: 1)
      Session.create(
        client_id: pa['client_id'],
        ip: pa['ip'],
        vhost: pa['vhost'],
        app: pa['app'],
        stream: pa['stream'],
        status: 1
      ) if clients.blank?
    elsif pa['action'] == 'on_stop'
      clients = Session.where(client_id: pa['client_id'], ip: pa['ip'], vhost: pa['vhost'], app: pa['app'], stream: pa['stream'], status: 1)
      clients.last.update(status: 0) unless clients.last.blank?
    else
      Rails.logger.info "sessions: #{__LINE__} bug, no this action, params is #{pa}"
    end
    render plain: '0', status: :ok
  end

  # on_dvr
  def dvrs
    render plain: '0', status: :ok
  end

  def hls
    render plain: '0', status: :ok
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
