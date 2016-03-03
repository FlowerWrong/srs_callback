require 'sidekiq/api'
require 'json'
require 'rest-client'

class Api::V1::SrsController < ApplicationController
  # @see https://github.com/ossrs/srs/wiki/v2_CN_HTTPCallback#http-callback-events

  # on_connect
  # on_close
  def clients
    render plain: '0', status: :ok
  end

  # on_publish
  # on_unpublish
  def streams
    pa = request.request_parameters
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

      # @see https://github.com/mperham/sidekiq/wiki/Active-Job#job-id
      # @see https://github.com/mperham/sidekiq/wiki/API
      # @see https://github.com/utgarda/sidekiq-status#unscheduling
      # FIXME why twice?
      live_transcodes = Transcode.where(ip: pa['ip'], vhost: pa['vhost'], app: pa['app'], stream: pa['stream'], status: 1)
      if live_transcodes.blank?
        live_clients = LiveClient.where(client_id: pa['client_id'], ip: pa['ip'], vhost: pa['vhost'], app: pa['app'], stream: pa['stream'], status: 1)
        if live_clients.blank?
          @lc = LiveClient.new(
            client_id: pa['client_id'],
            ip: pa['ip'],
            vhost: pa['vhost'],
            app: pa['app'],
            stream: pa['stream'],
            tc_url: pa['tcUrl'],
            status: 1
          )
          @lc.save
        end
      end
    elsif pa['action'] == 'on_unpublish'
      live_clients = LiveClient.where(client_id: pa['client_id'], ip: pa['ip'], vhost: pa['vhost'], app: pa['app'], stream: pa['stream'], status: 1)
      if live_clients.blank?
        @live_transcodes = Transcode.where(ip: pa['ip'], vhost: pa['vhost'], app: pa['app'], stream: pa['stream'], status: 1)
      else
        live_clients.each do |lc|
          lc.update(status: 0)
          @live_transcodes = lc.transcodes
        end
      end

      @live_transcodes.each do |lt|
        # FIXME how to del a job
        # flag = Sidekiq::Status.cancel(lt.job_id)
        # unless flag
        #   queue = Sidekiq::Queue.new
        #   queue.each do |job|
        #     job.delete if job.jid == lt.job_id
        #   end
        # end
        # @see http://stackoverflow.com/questions/34359912/how-to-kill-sidekiq-job-in-rails-4-with-activejob
        ps = Sidekiq::ProcessSet.new
        Rails.logger.info("Sidekiq process set are #{ps.size}, will be stoped")
        ps.each(&:stop!)

        # resque
        # Resque.queues.each{|q| Resque.redis.del "queue:#{q}" }
        lt.update(status: 0)
      end unless @live_transcodes.blank?
    else
      render(plain: 'auth failed', status: 401) && return
    end

    render plain: '0', status: :ok

    Thread.new do
      sleep 1
      scale_transcodes(@lc.id, pa)
      Rails.logger.info "on_publish thread status is #{Thread.current.status}"
      Thread.current.exit
    end if pa['action'] == 'on_publish' && !@lc.nil?
  end

  # on_play
  # on_stop
  # FIXME 每个客户端播放和停止播放的时候会发送两个请求过来
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
      res_json_str = ::RestClient.get("#{Settings.rtmp_api}/streams/")
      Rails.logger.info("res_json_str is #{res_json_str}")
      res_hash = JSON.parse(res_json_str)

      res_hash['streams'].each do |stream|
        if stream['name'] == pa['stream'] && stream['app'] = pa['app'] && stream['publish']['active']
          video_data_rate = stream['video']['video_data_rate']
          audio_data_rate = stream['audio']['audio_data_rate']
          bit_rate = video_data_rate.to_i + audio_data_rate.to_i

          stream_name = pa['stream']
          Rails.logger.info("#{stream_name}'s bit rate is #{bit_rate}")
          transcodes = []
          input_rtmp = "#{pa['tcUrl']}/#{stream_name}"

          stream_reg = /^([a-z|A-Z]+)_\d+p/ # livestream_420p
          origin_stream_name = stream_reg =~ stream_name ? $1 : stream_name
          output_rtmp_prefix = "#{pa['tcUrl']}/#{origin_stream_name}"

          # @see https://support.google.com/youtube/answer/2853702?hl=zh-Hans
          case bit_rate
          when 6000..10000 # 1080p@60fps -> 720p, 480p, 360p
            ['720p'].each do |transcode_stream|
              job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "#{output_rtmp_prefix}_#{transcode_stream}")
              transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
            end
          when 4000..6000 # 1080p -> 720p, 480p, 360p
            ['720p'].each do |transcode_stream|
              job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "#{output_rtmp_prefix}_#{transcode_stream}")
              transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
            end
          when 2500..4000 # 720p@60fps -> 480p, 360p
            ['480p'].each do |transcode_stream|
              job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "#{output_rtmp_prefix}_#{transcode_stream}")
              transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
            end
          when 1500..2500 # 720p -> 480p, 360p
            ['480p'].each do |transcode_stream|
              job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "#{output_rtmp_prefix}_#{transcode_stream}")
              transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
            end
          # when 1000..1500 # 480p -> 360p
          #   ['360p'].each do |transcode_stream|
          #     job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "#{output_rtmp_prefix}_#{transcode_stream}")
          #     transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
          #   end
          when 600..1500 # 360p
            ['240p'].each do |transcode_stream|
              job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "#{output_rtmp_prefix}_#{transcode_stream}")
              transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
            end
          when 0..600 # 240p
            # ['240p'].each do |transcode_stream|
            #   job = TranscodeJob.perform_later(transcode_stream, input_rtmp, "#{output_rtmp_prefix}_#{transcode_stream}")
            #   transcodes << {transcode_stream: transcode_stream, job_id: job.provider_job_id}
            # end
          end

          transcodes.each do |t|
            Transcode.create(
              live_client_id: live_client_id,
              input_rtmp: input_rtmp,
              output_rtmp: "#{output_rtmp_prefix}_#{t[:transcode_stream]}",
              ip: pa['ip'],
              vhost: pa['vhost'],
              app: pa['app'],
              stream: "#{pa['stream']}_#{transcode_stream}",
              status: 1,
              job_id: t[:job_id]
            )
          end
        end
      end unless res_hash['streams'].blank?
    end
  end
end
