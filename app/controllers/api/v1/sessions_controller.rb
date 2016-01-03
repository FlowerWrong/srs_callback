class Api::V1::SessionsController < ApplicationController
  # FIXME 计算四小时前到现在的
  # TODO only rtmp, no hls
  def index
    app = params[:app] || 'live'
    stream = params[:stream] || 'livestream'
    hours_ago = params[:hours_ago].to_i || 4
    now = Time.now
    base_h = {created_at: (now - hours_ago)..now, app: app, stream: stream}
    online_users = Session.where(base_h.merge!(status: 1)).count
    all_users = Session.where(base_h).count
    render json: {online_count: online_users, all_users_count: all_users}
  end
end
