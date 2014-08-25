require 'yeller/rails'

Yeller::Rails.configure do |config|
  config.token = 'YOUR API TOKEN HERE'
end

if Yeller::Rails.enabled?
  Rails.logger.info("cool, yeller is on")
else
  Rails.logger.info("yeller ain't on. Likely this is development or test mode")
end
