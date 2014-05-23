# encoding: utf-8

require 'date-utils'

module Project
  ##
  ## == LogDest ==
  ##
  ## Manage a particular, active logging destination.
  ##
  ## Each LogDest object provides the methods which write the logged data
  ## to an active destination (ie file handle).  The LogDest object also
  ## manages its own indentation and folding state.
  ##
  class LogDest
    attr_reader   :id, :level
    attr_accessor :disabled, :redirected
    attr_accessor :fname, :fh, :fhmustclose
    attr_accessor :indenting, :indent_depth, :indent_str
    attr_accessor :folding,   :folding_depth
    attr_accessor :timestamp

    def initialize(options = {})
      level = options[:level] || LEVEL_OUTPUT
      level = SYMBOLIC_LEVELS[level] if level.is_str?

      opts = {
          :disabled  => false,
          :indenting => true,
          :timestamp => false,
          :folding   => (level == LEVEL_OUTPUT) ? false : true,
      }.merge! options

      @level = level
      raise ArgumentError, "invalid :level (#{level.to_s})" unless
          level == LEVEL_OUTPUT or level == LEVEL_DEBUG

      # @redirected   = []
      @disabled     = opts[:disabled]
      @id           = opts[:id]
      @fname        = opts[:fname]
      @fh           = nil
      @fhmustclose  = false

      @indenting    = opts[:indenting] || true
      @indent_depth = 0
      @indent_str   =
          (indenting == true) ? (TAB * indent_depth) : EMPTY

      @folding       = (opts[:folding] == true) ? opts[:folding] : false
      @folding_depth = 0

      open

      raise ArgumentError, ":id is required" unless id.is_str?
    end

    ##
    # Called during {LogDest#initialize} to actually open the output file.
    #
    # Initialization call chain:
    #     LogDest.new => LogDest#initialize => LogDest#open => LogDest#_open
    #
    # {LogDest#open} doesn't actually open the output destination.  Instead,
    # the code which actually initializes the output destination is in
    # {LogDest#_open}, which subclasses can over-ride.
    #
    # Once {LogDest#_open} returns, {LogDest#open} verifies that the opened
    # stream provides everything the LogDest needs.
    ##
    def open()
      _open
      raise ArgumentError, ":fh provides no :print method" unless
          fh.respond_to? :print
      fh.sync = true if fh.respond_to? :sync=
    end

    ##
    # @see {LogDest#open}
    ##
    def _open()
      case fname
        when nil
          raise ArgumentError, ":fname is required"
        when :'>', :'>1', :STDOUT, :stdout
          @id ||= :STDOUT
          @fh = STDOUT
          @fhmustclose = false
        when :'>2', :STDERR, :stderr
          @id ||= :STDERR
          @fh = STDERR
          @fhmustclose = false
        else
          @fname = Pathname(@fname)
          @id ||= (@fname.basename @fname.extname).to_s.to_sym
          @fh = File.open(@fname.to_s, 'a')
          @fh.close_on_exec = true
          @fhmustclose = true
      end
    end

    ##
    # Close this LogDest object and release its resources.
    ##
    def close()
      unless fh.nil?
        # redirected.each { |rd| rd.close }

        fh.close if fhmustclose

        self.fh = nil
        self.fhmustclose = nil
        # self.redirected = []
      end
    end

    ##
    # Return the current indentation and folding state.
    ##
    def get_state()     [ indent_depth, folding_depth ]     end

    def restore_state(state)
      # state == [ indent_depth, folding_depth ]
      self.indent_depth = state[0]
      self.indent_str =
          (indenting == true) ? (TAB * indent_depth) : EMPTY

      upper = folding_depth - 1
      upper.downto(state[1]) do
        fh.puts FOLDING_CLOSE if folding and not disabled
        self.folding_depth -= 1
      end
    end

    ##
    # Adjust the indentation depth.  Returns the indent depth BEFORE it was adjusted.
    ##
    def adj_indent(adjust = 1)
      old, self.indent_depth = indent_depth, (indent_depth+adjust)
      self.indent_str =
          (indenting == true) ? (TAB * indent_depth) : EMPTY
      old
    end

    ##
    # Open a folding section.  Returns the folding depth BEFORE folding_open().
    ##
    def folding_open()
      self.folding_depth += 1
      fh.puts FOLDING_OPEN if folding and not disabled
      folding_depth - 1
    end

    def _bol(border)
      [
          timestamp ? "#{DateUtils.fmt_dt(DateTime.now)}| " : EMPTY,
          indent_str,
          border ? BORDER : EMPTY,
      ].join(EMPTY)
    end

    def writeln(text, border = false)
      return if disabled
      bol = _bol border
      bolnl = "\n" + bol
      fh.print bol, text.sub(/^\n+/u, EMPTY).gsub(/\n/su, bolnl), NL
      fh.flush
    end

    def writeln_here(text, border = false)
      return if disabled
      bol = _bol border
      bolnl = "\n" + bol
      fh.print text.sub(/\n+$/u, EMPTY).gsub(/\n/su, bolnl), NL
      fh.flush
    end

    def write(text, border = false)
      return if disabled
      bol = _bol border
      bolnl = "\n" + bol
      fh.print bol, text.sub(/^\n+/u, EMPTY).gsub(/\n/su, bolnl)
      fh.flush
    end

    def write_here(text, border = false)
      return if disabled
      bol = _bol border
      bolnl = "\n" + bol
      fh.print text.gsub(/\n/su, bolnl)
      fh.flush
    end
  end
end
