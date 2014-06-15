#!/usr/bin/env ruby

require_relative './test_helper'

# the run mode must be set BEFORE we require project
require 'brewed/date'

class Brewed_Tests < MiniTest::Test
  TEST_DATETIME = '2014-06-08 21:00'.freeze

  def test_sunday()
  end

  def test_monday()
  end

  def test_dow()
    time = Time.parse TEST_DATETIME
    dt   = DateTime.parse TEST_DATETIME
    assert_equal ::Brewed::Date.dow(time),  :sun, "dow(Time) succeeds"
    assert_equal ::Brewed::Date.dow(dt),    :sun, "dow(DateTime) succeeds"
  end

end
