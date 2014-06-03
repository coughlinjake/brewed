#!/usr/bin/env ruby

require_relative './test_helper'

class String_Tests < MiniTest::Test

  def test_safe_strip!()
    assert_equal 'this is a test',  '  this is a test   '.safe_strip!,  "safe_strip! actually performs strip!"
    assert_equal 'this is a test',  '  this is a test'.safe_strip!,     "safe_strip! with only leading actually performs strip!"
    assert_equal 'this is a test',  'this is a test   '.safe_strip!,    "safe_strip! with only trailing actually performs strip!"
    assert_equal 'this is a test',  'this is a test'.safe_strip!,       "safe_strip! returns self rather than nil"
    assert_equal 'none',            'none'.safe_strip!,                 "safe_strip! returns self when there is no whitespace"
  end

  def test_safe_gsub!()
    assert_equal 'this_is_a_test',  'this is a test'.safe_gsub!(/\s+/, '_'),  "safe_gsub! actually performs gsub!"
    assert_equal 'this_is_a_test',  'this_is_a_test'.safe_gsub!(/\s+/, '_'),  "safe_gsub! returns self rather than nil"
  end

end
