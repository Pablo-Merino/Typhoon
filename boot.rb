#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'

pwd = Dir.pwd
Daemons.run_proc('Typhoon', {:dir_mode => :normal, :dir => "#{pwd}/pid/"}) do
  Dir.chdir(pwd)
  exec 'ruby s.rb'
end