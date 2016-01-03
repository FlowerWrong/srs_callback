SrsCallback::Application.configure do
  config.lograge.enabled = true

  config.lograge.ignore_actions = ['srs#clients', 'srs#streams', 'srs#dvrs', 'srs#hls']
  # config.lograge.ignore_custom = lambda do |event|
  # end

  config.lograge.logger = ActiveSupport::Logger.new "#{Rails.root}/log/lograge_#{Rails.env}.log"
end
