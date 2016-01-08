# require 'awesome_print' if Rails.env != 'production'

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
      # p "white_ips.include? client_ip is #{white_ips.include? client_ip}"
      unless white_ips.include? client_ip
        # 再验证token
        white_tokens = Settings.token_list.split(' ')
        client_token = pa['tcUrl'].last(32)
        # p "white_tokens.include? client_token is #{white_tokens.include? client_token}"
        unless white_tokens.include? client_token
          render(plain: 'auth failed', status: 401) && return
        end
      end
    elsif pa['action'] == 'on_unpublish'
    else
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
