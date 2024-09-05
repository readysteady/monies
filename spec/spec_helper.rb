require 'simplecov'

SimpleCov.start do
  track_files 'lib/**/*.rb'

  add_filter 'spec/'
end

require_relative '../lib/monies'
require 'bigdecimal/util'
require 'percentage'
