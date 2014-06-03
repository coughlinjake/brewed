#!/usr/bin/env ruby

require_relative './test_helper'

# the run mode must be set BEFORE we require project
require 'wad'

# require 'minitest/autorun'
# require 'minitest/reporters'
# MiniTest::Reporters.use!

class Wad_Tests < MiniTest::Test
  TEST_HOME          = '/Users/jakec'
  TEST_HOST          = 'bigmac'
  TEST_MODE          = ENV['ITUNES_MODE'].to_sym
  TEST_WAD_NAME      = 'iTunes'

  TEST_WAD_ROOT      = "#{TEST_HOME}/UNISON/src/ruby/#{TEST_WAD_NAME}"
  TEST_WAD_LIB       = "#{TEST_HOME}/UNISON/src/ruby/#{TEST_WAD_NAME}/lib"
  TEST_WAD_STATEROOT = "#{TEST_HOME}/state/#{TEST_HOST}/#{TEST_WAD_NAME.downcase}"
  TEST_WAD_LOG       = "#{TEST_WAD_STATEROOT}"
  TEST_WAD_STATE     = "#{TEST_WAD_STATEROOT}/#{TEST_MODE}"

  def test_libdir()
   # puts "Wad.libdir: '#{Wad.libdir}'"
    assert_equal Wad.libdir,
                 TEST_WAD_LIB,
                 "Wad.libdir = '#{TEST_WAD_LIB}'"
  end
  def test_hostname()
    assert_equal Wad.hostname,
                 TEST_HOST,
                 "Wad.hostname = '#{TEST_HOST}'"
  end
  def test_home()
    assert_equal Wad.home,
                 TEST_HOME,
                 "Wad.home = '#{TEST_HOME}'"
  end
  def test_mode()
    assert_equal Wad.run_mode,
                 TEST_MODE,
                 "Wad.run_mode = '#{TEST_MODE}'"
  end
  def test_project()
    assert_equal Wad.instance.libdir,
                 TEST_WAD_LIB,
                 "Wad.instance.libdir = '#{TEST_WAD_LIB}'"
  end
  def test_state_root()
    assert_equal Wad.instance.state_root,
                 TEST_WAD_STATEROOT,
                 "Wad.instance.state_root = '#{TEST_WAD_STATEROOT}'"
  end
  def test_log()
    assert_equal Wad.log,
                 TEST_WAD_LOG,
                 "Wad.log = '#{TEST_WAD_LOG}'"
  end
  def test_state()
    assert_equal Wad.state,
                 TEST_WAD_STATE,
                 "Wad.state = '#{TEST_WAD_STATE}'"
  end
end
