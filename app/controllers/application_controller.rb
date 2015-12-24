class ApplicationController < ActionController::API
  def index
    render text: 'hello', status: :ok
  end
end
