class ApplicationController < ActionController::Base
  def hello
    render html: 'hello, workd'
  end
end
