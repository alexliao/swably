# Load the rails application
require File.expand_path('../application', __FILE__)

ENV['lang'] = 'en'
ENV['host'] = 'swably.com' # for generating url
ENV['admin_pwd'] = 'gaofei888' # for enter admin UI
ENV['connections_en'] = "twitter facebook plus"
ENV['connections_zh'] = "sina"
ENV['connections'] = ENV['connections_en'] + " " + ENV['connections_zh']

# Initialize the rails application
Swably::Application.initialize!

