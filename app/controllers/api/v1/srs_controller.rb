require 'sidekiq/api'

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
          lc = LiveClient.new(
            client_id: pa['client_id'],
            ip: pa['ip'],
            vhost: pa['vhost'],
            app: pa['app'],
            stream: pa['stream'],
            tc_url: pa['tcUrl'],
            status: 1
          )
          lc.save

          ScaleTranscodeJob.perform_later([pa, lc.id], 'rtmp://192.168.10.160/live/demo')
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
        flag = Sidekiq::Status.cancel(lt.job_id)
        unless flag
          queue = Sidekiq::Queue.new
          queue.each do |job|
            job.delete if job.jid == lt.job_id
          end
        end
        lt.update(status: 0)
      end unless @live_transcodes.blank?
    else
      render(plain: 'auth failed', status: 401) && return
    end

    render plain: '0', status: :ok
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
end
