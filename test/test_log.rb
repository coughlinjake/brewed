#!/usr/bin/env ruby

require_relative './test_helper'

# the run mode must be set BEFORE we require project
require 'brewed'

class Log_Tests < MiniTest::Unit::TestCase

  def test_stdout()
    Log.open :'>1', :output
    Log.Info "this is going into the log file"
    Log.Out  "this is only going to STDOUT"
    dest = Log.get_destinations

    Log.reopen
    Log.Info "new log output"
    Log.Out  "still able to write to STDOUT"
    dest2 = Log.get_destinations

    puts "HERE!"
  end

end

