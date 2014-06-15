require 'pathname'

class TestHelper
  TEST_DIR   = Pathname.new(__FILE__).expand_path.dirname.freeze
  DATA_DIR   = (TEST_DIR + 'data').freeze
  LIB_DIR    = (TEST_DIR.dirname + 'lib').freeze
end

[
    TestHelper::LIB_DIR.to_s,
].each { |p| $LOAD_PATH.unshift(p) unless $LOAD_PATH.include? p }

gem 'minitest'
require 'minitest/autorun'
# require 'minitest/reporters'
# MiniTest::Reporters.use!

require 'psych'
require 'brewed'
require 'brewed/data'

class TestHelper
  def data_dir(*paths)        self.class.data_dir(*paths)         end
  def self.data_dir(*paths)  ([DATA_DIR, *paths].reduce :+).to_s  end

  def dump_file(fname, obj)
    File.open(fname, 'w') { |fh| fh.print( Psych.dump(obj) ) }
  end

  def load_file(fname)
    Psych.load_file fname
  end

  def load_string(yamlstr)
    Psych.load yamlstr
  end

end

$TH = TestHelper.new
