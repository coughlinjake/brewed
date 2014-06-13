# encoding: utf-8

module Brewed
  ##
  ## == BrewedLog ==
  ##
  class BrewedLog
    attr_reader   :log_index, :out_logs, :debug_logs, :failures

    def initialize()
      @failures   = []
      @log_index  = {}
      @out_logs   = []
      @debug_logs = []
    end

    ##
    # Begin logging to a new active log destination.
    #
    # The destination may be provided as an instantiated LogDest object, or
    # the parameters for creating a LogDest can be provided and {Log#open}
    # will instantiate a new LogDest object.
    #
    # @param options [Hash]
    # @option options :dest   [nil, LogDest]
    # @see {LogDest#initialize}
    #
    # @return [void]
    ##
    def open(options = {})
      dest = options[:dest]
      destid  = nil
      begin
        dest = BrewedLogDest.new options if dest.nil?

        destid  = dest.id

        raise ArgumentError, "dest id '#{destid}' already open" unless
            log_index[destid].nil?
        log_index[destid] = dest

        if dest.level == LEVEL_DEBUG
          # debug level only goes to debug logs
          debug_logs.push dest
        else
          # output level goes everywhere
          out_logs.push dest
        end
      rescue ArgumentError => exp
        dest.close if dest.respond_to? :close
        raise exp
      end
    end

    ##
    # Close the provided log destination.
    #
    # @param dest [Symbol, Dest]
    ##
    def close(dest)
      dest = get_dest dest if dest.is_str?
      if dest.respond_to? :id
        destid = dest.id
        if log_index.key? destid
          raise ArgumentError, "different log objects" unless
              log_index[destid] == dest

          log_index.delete  destid
          out_logs.delete   dest    if out_logs.include? dest
          debug_logs.delete dest    if debug_logs.include? dest

          dest.close
        end
      end
    end

    ##
    # Get a log destination from its id.
    #
    # @param destid [Symbol]
    # @return [LogDest]
    ##
    def get_dest(destid)
      log_index[destid]
    end

    ##
    # Record a failure.
    ##
    def fail(msgs)
      failures.push msgs.join("\n")

      fail_msg = [:h1, "==FAILURES REPORTED=="]
      fail_msg << msgs
      output [out_logs, debug_logs].flatten, fail_msg
    end

    ##
    # Output messages at debug level.
    ##
    def debug(msgs, &block)
      if block
        indent_output dest_for_level(LEVEL_DEBUG), msgs, &block
      else
        output dest_for_level(LEVEL_DEBUG), msgs
      end
    end

    ##
    # Output messages at output level.
    ##
    def out(msgs, &block)
      if block
        indent_output [out_logs, debug_logs].flatten, msgs, &block
      else
        output [out_logs, debug_logs].flatten, msgs
      end
    end

    ##
    # Output msgs at the current indent level then increase the ident depth
    # for the duration of the provided block.  When the block returns,
    # restore the indent level.
    #
    # The default adjustment is to increase indent depth by 1, but if
    # the first parameter is an Integer, the indent depth will be adjusted
    # by that Integer.
    #
    # @param dests  [Array<LogDest>]
    # @param msgs   [Array<(Integer, Object, Object,...)>]
    # @return block result
    ##
    def indent_output(dests, msgs)
      adjindent =
          (msgs.length > 0 and msgs[0].is_a?(Integer)) ? msgs.shift : 1
      adjindent = 1 if adjindent == 0

      raise ArgumentError, "indent_output requires a block be provided" unless
          block_given?

      # current msgs are output at current indent depth
      output dests, msgs

      # pre-allocate an array to remember the current state of every destination.
      # then increase indentation and open a folding context
      restore = [nil] * dests.length
      dests.each_with_index do |dest, index|
        restore[index] = dest.get_state
        dest.adj_indent adjindent
        dest.folding_open
      end

      rc = nil
      begin
        rc = yield
      ensure
        # restore the state for every destination
        dests.each_with_index { |dest, index| dest.restore_state restore[index] }
      end

      rc
    end

    private

    def dest_for_level(level)
      (level == LEVEL_DEBUG) ? debug_logs : out_logs
    end

    def write(dests, text, border = false)    dests.each { |dest| dest.write text, border }   end
    def write_here(dests, text)               dests.each { |dest| dest.write_here text }      end
    def writeln(dests, text, border = false)  dests.each { |dest| dest.writeln text, border } end
    def writeln_here(dests, text)             dests.each { |dest| dest.writeln_here text }    end

    FORMATTING = {
        :h1 => '{**} ',
        :h2 => '{++} ',
        :h3 => '{--} ',
        :h4 => ' {*} ',
        :h5 => ' {+} ',
        :h6 => ' {-} ',
    }.freeze
    SINGLETONS = {
        true  => "\tTRUE",
        false => "\tFALSE",
        nil   => "\tNIL",
    }.freeze

    def output(dests, msgs)
      s = nil
      while msgs.length > 0
        m   = msgs.shift
        if m.is_a? String
          # writeln dests, m.sub(/^\t+/, '')
          writeln dests, m

        elsif (s = SINGLETONS[m])
          writeln dests, s

        elsif m == :sep
          writeln dests, SINGLE_LINE

        elsif (s = FORMATTING[m])
          writeln       dests, EMPTY      # force line break
          write         dests, s          # write indented format str WITHOUT NL
          writeln_here  dests, msgs.shift

        else
          writeln       dests, "[= #{m.class.to_s} =]", true
          writeln_here  dests, FOLDING_OPEN
          writeln       dests, Psych.dump(m), true
          writeln_here  dests, FOLDING_CLOSE
        end
      end
    end
  end
end
