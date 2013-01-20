require 'rubygems'
require 'sinatra'
require './app'

use Rack::Session::Cookie, :key => 'trd_key',
                           :path => '/',
                           :expire_after => 14400, # In seconds
                           :secret => 'manjusri'

run Sinatra::Application
