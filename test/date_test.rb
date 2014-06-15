#!/usr/bin/env ruby

require_relative './test_helper'

# the run mode must be set BEFORE we require project
require 'brewed/date'

class Brewed_Tests < MiniTest::Test
  TEST_DATETIME  = '2014-06-08 21:00'.freeze
  TEST_DATE_TO_DATETIME = '2014-06-08 00:00'.freeze

  TEST_DATETIME2 = '2014-04-04 10:00'.freeze
  TEST_DATE_TO_DATETIME2 = '2014-04-04 00:00'.freeze

  def test_monday()
    [
        [ '2014-04-22',       '2014-04-21' ],
        [ '2014-04-22 14:30', '2014-04-21' ],
        [ '2013-11-15',       '2013-11-11' ],
        [ '2013-11-15 11:59', '2013-11-11' ],
        [ '2012-02-12',       '2012-02-06' ],
        [ '2012-02-12 23:59', '2012-02-06' ],
    ].each do |(dt, exp)|
      mon = Date.parse exp
      assert_equal ::Brewed::Date.monday(dt).to_date, mon, "monday('#{dt}') == '#{exp}'"
    end
  end

  def test_sunday()
    [
        [ '2014-04-22',       '2014-04-20' ],
        [ '2014-04-22 14:30', '2014-04-20' ],
        [ '2013-11-15',       '2013-11-10' ],
        [ '2013-11-15 11:59', '2013-11-10' ],
        [ '2012-02-12',       '2012-02-05' ],
        [ '2012-02-12 23:59', '2012-02-05' ],
    ].each do |(dt, exp)|
      sun = Date.parse exp
      assert_equal ::Brewed::Date.sunday(dt).to_date, sun, "sunday('#{dt}') == '#{exp}'"
    end
  end

  def test_dow()
    [
        [ TEST_DATETIME, :sun ],
        [ TEST_DATETIME2, :fri ],
    ].each do |(dt, dow)|
      assert_equal ::Brewed::Date.dow( Time.parse(dt) ),      dow, "dow(Time[#{dt.to_s}]) == '#{dow}'"
      assert_equal ::Brewed::Date.dow( DateTime.parse(dt) ),  dow, "dow(DateTime[#{dt.to_s}]) == '#{dow}'"
      assert_equal ::Brewed::Date.dow( Date.parse(dt) ),      dow, "dow(Date[#{dt.to_s}]) == '#{dow}'"
    end
  end

  ## NOTE: these coersions seem like weird things to have to test, but
  ## inheritance actually makes the coersion more subtle than i originally
  ## thought!
  def test_to_date()
    test_datetime  = ::Date.parse(TEST_DATETIME)
    test_datetime2 = ::Date.parse(TEST_DATETIME2)
    [
        [ ::Date.parse(TEST_DATETIME),  test_datetime  ],
        [ ::Date.parse(TEST_DATETIME2), test_datetime2 ],
        [ ::DateTime.parse(TEST_DATETIME), test_datetime ],
        [ ::DateTime.parse(TEST_DATETIME2), test_datetime2 ],
    ].each do |(dtobj, exp)|
      assert_equal ::Brewed::Date.to_date(dtobj).class,   ::Date,   "#{dtobj.class.to_s}.to_date => ::Date"
      assert_equal ::Brewed::Date.to_date(dtobj),         exp,      "#{dtobj.class.to_s}.to_date == #{exp.to_s}"
    end
  end

  def test_to_datetime()
    test_date  = ::DateTime.parse(TEST_DATE_TO_DATETIME)
    test_datetime  = ::DateTime.parse(TEST_DATETIME)

    test_date2 = ::DateTime.parse(TEST_DATE_TO_DATETIME2)
    test_datetime2 = ::DateTime.parse(TEST_DATETIME2)

    [
        [ ::Date.parse(TEST_DATETIME),  test_date  ],
        [ ::Date.parse(TEST_DATETIME2), test_date2 ],
        [ ::DateTime.parse(TEST_DATETIME), test_datetime ],
        [ ::DateTime.parse(TEST_DATETIME2), test_datetime2 ],
    ].each do |(dtobj, exp)|
      assert_equal ::Brewed::Date.to_datetime(dtobj).class, ::DateTime, "#{dtobj.class.to_s}.to_datetime => ::DateTime"
      assert_equal ::Brewed::Date.to_datetime(dtobj),       exp,        "#{dtobj.class.to_s}.to_datetime == #{exp.to_s}"
    end
  end

end
