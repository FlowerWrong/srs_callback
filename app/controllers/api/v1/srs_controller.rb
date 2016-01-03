require 'awesome_print' if Rails.env == 'production'

class Api::V1::SrsController < ApplicationController
  # @see https://github.com/ossrs/srs/wiki/v2_CN_HTTPCallback#http-callback-events

  # on_connect
  # on_close
  def clients
    # pa = request.request_parameters
    # ap pa
    # {
    #        "action" => "on_connect",
    #     "client_id" => 211,
    #            "ip" => "192.168.10.196",
    #         "vhost" => "__defaultVhost__",
    #           "app" => "live",
    #         "tcUrl" => "rtmp://192.168.10.160:1935/live",
    #       "pageUrl" => "",
    #            "sr" => {
    #            "action" => "on_connect",
    #         "client_id" => 211,
    #                "ip" => "192.168.10.196",
    #             "vhost" => "__defaultVhost__",
    #               "app" => "live",
    #             "tcUrl" => "rtmp://192.168.10.160:1935/live",
    #           "pageUrl" => ""
    #     }
    # }
    # if pa['action'] == 'on_connect'
    #   if pa['pageUrl'].blank?
    #     # rtmp push flow
    #   else
    #     # client
    #   end

    # {
    #         "action" => "on_close",
    #      "client_id" => 211,
    #             "ip" => "192.168.10.196",
    #          "vhost" => "__defaultVhost__",
    #     "send_bytes" => 0,
    #     "recv_bytes" => 0,
    #            "app" => "live",
    #             "sr" => {
    #             "action" => "on_close",
    #          "client_id" => 211,
    #                 "ip" => "192.168.10.196",
    #              "vhost" => "__defaultVhost__",
    #         "send_bytes" => 0,
    #         "recv_bytes" => 0,
    #                "app" => "live"
    #     }
    # }
    # elsif pa['action'] == 'on_close'
    # else
    # end
    render plain: '0', status: :ok
  end

  # on_publish
  # on_unpublish
  def streams
    # pa = request.request_parameters
    # ap pa
    # {
    #        "action" => "on_publish",
    #     "client_id" => 211,
    #            "ip" => "192.168.10.196",
    #         "vhost" => "__defaultVhost__",
    #           "app" => "live",
    #        "stream" => "livestream",
    #            "sr" => {
    #            "action" => "on_publish",
    #         "client_id" => 211,
    #                "ip" => "192.168.10.196",
    #             "vhost" => "__defaultVhost__",
    #               "app" => "live",
    #            "stream" => "livestream"
    #     }
    # }
    # if pa['action'] == 'on_publish'

    # {
    #        "action" => "on_unpublish",
    #     "client_id" => 211,
    #            "ip" => "192.168.10.196",
    #         "vhost" => "__defaultVhost__",
    #           "app" => "live",
    #        "stream" => "livestream",
    #            "sr" => {
    #            "action" => "on_unpublish",
    #         "client_id" => 211,
    #                "ip" => "192.168.10.196",
    #             "vhost" => "__defaultVhost__",
    #               "app" => "live",
    #            "stream" => "livestream"
    #     }
    # }
    # elsif pa['action'] == 'on_unpublish'
    # else
    # end

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
    # pa = request.request_parameters
    # ap pa
    # if pa['action'] == 'on_dvr'
    # else
    # end
    render plain: '0', status: :ok
  end

  def hls
    # pa = request.request_parameters
    # ap pa
    # if request.method == 'POST'
    #   if pa['action'] == 'on_hls'
    #   else
    #   end
    # elsif request.method == 'GET'
    # else
    # end
    render plain: '0', status: :ok
  end
end
