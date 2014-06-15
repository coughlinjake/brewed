#!/usr/bin/env ruby

require_relative './test_helper'

# the run mode must be set BEFORE we require project
require 'brewed'

class Brewed_Tests < MiniTest::Test
  TEST_HOME          = Pathname.new( Dir.home )
  TEST_HOST          = :bigmac
  TEST_MODE          = ENV['BREWED_MODE'].to_sym
  TEST_BREWED_NAME   = 'brewed'

  TEST_BREWED_ROOT      = Pathname.new(__FILE__).expand_path.dirname.dirname
  TEST_BREWED_LIB       = TEST_BREWED_ROOT + 'lib'
  TEST_BREWED_STATEROOT = TEST_HOME + 'state' + TEST_HOST.to_s + TEST_BREWED_NAME.downcase
  TEST_BREWED_LOG       = TEST_BREWED_STATEROOT + TEST_MODE.to_s
  TEST_BREWED_STATE     = TEST_BREWED_STATEROOT + TEST_MODE.to_s

  def test_libdir()
   # puts "Brewed.libdir: '#{Brewed.libdir}'"
    assert_equal Brewed.libdir,
                 TEST_BREWED_LIB,
                 "Brewed.libdir = '#{TEST_BREWED_LIB}'"
  end
  def test_hostname()
    assert_equal Brewed.hostname,
                 TEST_HOST,
                 "Brewed.hostname = '#{TEST_HOST}'"
  end
  def test_home()
    assert_equal Brewed.home,
                 TEST_HOME,
                 "Brewed.home = '#{TEST_HOME}'"
  end
  def test_mode()
    assert_equal Brewed.run_mode,
                 TEST_MODE,
                 "Brewed.run_mode = '#{TEST_MODE}'"
  end
  def test_project()
    assert_equal Brewed.libdir,
                 TEST_BREWED_LIB,
                 "Brewed.instance.libdir = '#{TEST_BREWED_LIB}'"
  end
  def test_state_root()
    assert_equal Brewed::BrewedBase.instance.state_root,
                 TEST_BREWED_STATEROOT,
                 "Brewed.instance.state_root = '#{TEST_BREWED_STATEROOT}'"
  end
  def test_log()
    assert_equal Brewed.log,
                 TEST_BREWED_LOG,
                 "Brewed.log = '#{TEST_BREWED_LOG}'"
  end
  def test_state()
    assert_equal Brewed.state,
                 TEST_BREWED_STATE,
                 "Brewed.state = '#{TEST_BREWED_STATE}'"
  end
end
