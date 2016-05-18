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
      unless @live_transcodes.blank?
        @live_transcodes.each do |lt|
          # Process.kill('KILL', lt.pid)
          lt.update(status: 0)
        end
        # FIXME
        `killall -KILL ffmpeg` # kill all ffmpeg, there is a bug with sh -c
      end

      # 再标记直播流
      live_clients.each { |lc| lc.update(status: 0) }
      # 清楚所有的hls缓存
      HlsCleanupJob.perform_later(pa['app'], pa['stream'])
    else
      render(plain: 'auth failed', status: 401) && return
    end

    render plain: '0', status: :ok

    # FIXME bug when puma
    if pa['action'] == 'on_publish' && !@lc.nil?
      ScaleJob.perform_later(@lc.id, pa)
    end
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
end
