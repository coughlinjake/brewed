# encoding: utf-8

require 'singleton'
require 'time'
require 'pathname'
require 'psych'

module Project
  TAB = "\t".freeze
  NL = "\n".freeze
  EMPTY = ''.freeze
  BORDER = ' | '.freeze
  FOLDING_OPEN = '|{'.freeze
  FOLDING_CLOSE = '}|'.freeze
  DOTDOTDOT = '...'.freeze

  DOUBLE_LINE = ('=' * 80).freeze
  SINGLE_LINE = ('-' * 80).freeze

  LEVEL_OUTPUT = 1.freeze
  LEVEL_DEBUG = 5.freeze

  NUMERIC_LEVELS = [
      nil, :output, nil, nil, nil, :debug
  ].freeze
  SYMBOLIC_LEVELS = {
      :output => LEVEL_OUTPUT,
      :debug => LEVEL_DEBUG,
  }.freeze
end


require 'project/log/pretty'
require 'project/log/dest'
# require 'log/redirected'
require 'project/log/log'

##
## Log Interface
##
class Log < Project::Log
  include Singleton

  def initialize()
    super
  end

  ##
  # Open a logging destination, optionally with its own severity level.
  #
  # The default severity level is :info.
  #
  # STDOUT, STDERR can be specified as logging destinations using the
  # special filenames:
  #
  # * :'>', :'>1', :STDOUT
  #   open STDOUT as a destination
  #
  # * :'>>', :'>>1'
  #   open STDOUT for appending as destination
  #
  # * :'>2', :'>>2', :STDERR
  #   open STDERR for appending as destination
  #
  # @param fname [String]
  # @param level [:error, :warn, :info, :debug]
  #
  ##
  def self.open(*parms)
    instance.open(*parms)
  end

  ##
  # Close a logging destination.
  #
  # If fname is nil, ALL logging destinations are closed.
  #
  # @param fname [String]
  ##
  def self.close(*parms)
    instance.close(*parms)
  end

  def self.get_dest(*parms)
    instance.get_dest(*parms)
  end

  ##
  # Get or set options for the log.
  ##
  #def self.options(*parms)            instance.options(*parms)  end

  def self.Out(*msgs, &block)
    instance.out msgs, &block
  end

  ##
  # Write a message to the log, increase the log indentation level for a block
  # of code and restore it when the code returns.
  #
  # @param level [Integer]    (Optional) increase indentation this many levels
  # @param msg [String]       list of strings that will be concat and passed to {Log#info}.
  # @return [Object]          return value from +yield+
  #
  # If a block is provided, the msg is logged at the current indentation level,
  # and the indentation level is increased during that block ONLY.
  #
  # If no block is provided, the indentation level is increased BEFORE the
  # message is logged.  {Log#back} must be called to decrease the indentation level.
  #
  # Returns whatever #yield returns.
  #
  # @example Log a variable name and its value
  #    Log.Info 'BAD OBJECT:', bad_object
  #
  # @example Log message, indent 2 tabstops, process the block and decrease 2 tabstops
  #    Log.Info(2, "Look, MA!  Just 1 call to Log#Info") {
  #        call.so_and_so('DUDE!  that's phantsy!')
  #    }
  ##
  def self.Debug(*msgs, &block)
    instance.debug msgs, &block
  end

  ##
  # Record a failure.
  ##
  def self.Fail(*msgs)
    instance.fail msgs
  end

  ##
  # Retrieve an Array containing ALL of the recorded failures.
  ##
  def self.Failures()
    instance.failures
  end

  ##
  # Format an Exception object as a String.
  ##
  def self.exception_to_string(exp)
    "EXCEPTION #{exp.class.to_s}: #{exp.message}\n\t#{exp.backtrace.join("\n\t")}"
  end
end

# automatically create a logging destination which writes :output
# level messages to STDOUT
Log.open :id => :stdout, :fname => :STDOUT, :level => :output
