require 'rubygems'
require 'sinatra'
require './app'

log = File.new("sinatra.log", "a+")
$stdout.reopen(log)
$stderr.reopen(log)

run Sinatra::Application
