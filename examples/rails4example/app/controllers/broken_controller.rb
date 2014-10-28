class BrokenController < ApplicationController
  def index
    raise 'error'
  end

  def current_user
    OpenStruct.new(id: rand(6).abs)
  end
end
