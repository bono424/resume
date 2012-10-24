require 'rubygems'
require 'sinatra'
require './app'

run Sinatra::Application

set :database, ENV['DATABASE_URL'] || 'postgres://localhost/scottsansovich'
