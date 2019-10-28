require './server.rb'

run Rack::URLMap.new('/sidekiq' => Sidekiq::Web)
