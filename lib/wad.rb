# encoding: utf-8

# = Wad.rb
#
# == Environment Variables
#
# HOSTNAME
# : name of host application is executing on
#
# *WAD_NAME*_MODE
# : `dev`, `test`, `production`
#
# == Application State
#
# State directory:
#
#      [HOME]/state/[HOSTNAME]/[WAD_NAME]/[WAD_MODE]
#

require 'singleton'
require 'pathname'

module Wad

  class WadBase
    include Singleton

    LIBDIR = Pathname.new(__FILE__).dirname.expand_path.freeze
    REAL_LIBDIR = Pathname.new(__FILE__).expand_path.realpath.dirname.freeze

    BINSTR = 'bin'.freeze
    LIBSTR = 'lib'.freeze

    ##
    # Determine the wad directory.
    #
    # @note IMPORTANT ASSUMPTIONS:
    #
    #    1. $0 contains the path of the currently executing script.
    #
    #    2. $0 is either an ABSOLUTE path or
    #       it's ALWAYS relative to the current directory.
    #
    #    3. $0 ends with a FILENAME (ie the script)
    ##
    def self.find_wad_dir()
      dir = (Pathname.getwd + $0).realpath
      begin
        dir = dir.dirname
      end until (dir + BINSTR).directory? and (dir + LIBSTR).directory?
      dir
    end

    WAD_DIR = find_wad_dir.freeze

    def self.add_load_path(dir)
      fulldir = Pathname.new(dir).expand_path
      fulldir = fulldir.dirname unless fulldir.directory?
      $LOAD_PATH.unshift(fulldir) unless $LOAD_PATH.include? fulldir
    end

    def self.bootstrap()
      # add the real lib dir first so that wad local files can over-ride global files
      add_load_path REAL_LIBDIR
      add_load_path LIBDIR
      add_load_path WAD_DIR
    end

    def self.wad_relative(path)
      fullpath = Pathname.new(path).expand_path
      fullpath.relative_path_from WAD_DIR
    end

    ##
    #
    # @param submodule [String,Pathname]
    #    the absolute path to a Ruby module filename.
    #    +$LOAD_PATH+ will be updated to contain +submodule+'s dirname.
    ##
    def self.require_sub_modules(submodule)
      submod_path = wad_relative submodule

      # remove both the dirname and the file extension from this filename
      # 'app/models/tv.rb' => 'tv'
      submod_base = submod_path.basename submod_path.extname

      # 'app/models/tv.rb' => 'app/models'
      submod_dir = submod_path.dirname

      mod_root = submod_dir + submod_base
      #puts "requiring #{mod_root.to_s}"
      require mod_root.to_s

      # find all filenames matching the glob "#{submod_dir}/#{submod_base}/*.rb"
      Dir.glob(WAD_DIR + mod_root + '*.{rb,rbo}').
          map { |mabs| Pathname.new(mabs.chomp(File.extname(mabs))).relative_path_from(WAD_DIR) }.
          uniq.each do |modname|
        #puts "requiring #{modname.to_s}"
        require modname.to_s
      end
    end
  end

  ##
  ## Bootstrap the wad's execution/load environment.
  ##
  WadBase.bootstrap

  require 'data-utils'

  class WadBase
    attr_accessor :dir, :script_name, :host, :home_dir,
                  :name, :run_mode,
                  :_log_root, :_log_filename,
                  :_lock_dir,
                  :_public,
                  :_working_dir,
                  :_state_root, :state_dir,
                  :settings

    def initialize()
      @script_name = Pathname.new($0 || 'UNKNOWN_SCRIPT').basename.to_s

      @host = @state_dir = @run_mode = ''

      # @note Wad assumes:
      #    * it's located somewhere in lib directory tree,
      #    * the root of that **lib** tree is a directory named "lib"
      #    * there are no intermediate directories between "lib" and wad.rb also named "lib"
      #    * the parent of "lib" is the root of the wad
      #
      # therefore, work our way backward back up the directory tree until we
      # reach a directory with a child dir named "lib"
      @dir = WAD_DIR
      @name = WAD_DIR.basename.to_s.downcase

      # set the host name
      hostname

      @home_dir = Pathname.new Dir.home

      @_log_root = @_log_filename = @_working_dir = @_public = nil

      if name == 'ruby'
        # loading system application from /usr/local/bin
        # "global" settings dir
        @run_mode = :disabled

        @settings = [WAD_DIR, @host.is_str? ? @host : [], $PROGRAM_NAME].flatten.reduce :+

        @_log_root = home_dir + 'Library/Logs'
        raise "invalid log_root: '#{_log_root}" unless _log_root.directory?

        @_state_root = nil
        @state_dir = nil

      else
        # loading from private application directory structure:
        # ../@name/
        #    @name/public
        #    @name/settings
        @_public = WAD_DIR + 'public'
        @settings = WAD_DIR + 'settings'

        # @note set_run_mode also sets state directories
        set_run_mode
      end

      @_lock_dir = @state_dir + 'LOCKS'
    end

    ##
    # Return an absolute path within the working directory.
    #
    # The working directory is determined:
    #   * value of WAD_WORKING_DIR env var
    #   * When run_mode is :daemon, the working dir is state_dir.
    #   * Otherwise, the current directory.
    #
    # @param [Array<String>]
    # @return [Pathname]
    ##
    def working_dir(*path)
      if _working_dir.nil?
        @_working_dir = ENV['PROJECT_WORKING_DIR']
        if _working_dir != nil
          @_working_dir = Pathname.new(expand_variables _working_dir)
          Dir.chdir _working_dir.to_s

        elsif run_mode == :daemon
          @_working_dir = state_dir
          Dir.chdir _working_dir.to_s

        else
          @_working_dir = Pathname.getwd
        end

        raise "working_dir not a directory: #{_working_dir.safe_s}" unless _working_dir.directory?
      end
      [_working_dir, *path].reduce(:+)
    end

    def log_root()
      if _log_root.nil?
        # @note Since the working dir is always state_dir when run_mode == :daemon,
        #    then @_log_root is ALWAYS state_dir.
        @_log_root = (run_mode == :daemon) ? working_dir : state_dir
      end
      _log_root
    end

    def log_filename()
      if _log_filename.nil?
        @_log_filename = ENV['PROJECT_LOG_FILE']
        @_log_filename =
            _log_filename ?
                Pathname.new(expand_variables _log_filename) :
                (log_root + "#{name}.log")
      end
      _log_filename
    end

    ##
    # Provide the absolute path to this Wad's lib dir.
    #
    # @return [String]
    ##
    def libdir()
      LIBDIR
    end

    ##
    # Sets the current application run mode.
    #
    # Use {Wad#run_mode} to query the application's run mode.
    #
    # @note During initialization (probably before the application code starts),
    #    the run mode is set from the value of the application's run mode
    #    environment variable.  The variable name is constructed by uppercasing
    #    the application name (see {Wad#name}) and appending '_MODE'.
    #    The value of this environment variable should be one of:
    #    'production', 'dev', 'test'.
    #
    # @note Depending on the application, this can be a DANGEROUS thing to do
    #    once the application starts executing.  DataMapper applications, for
    #    example, may open/create databases based on the run mode as defined
    #    during the application's initialization BEFORE the application has a
    #    chance to over-ride the mode.
    #
    # @example Set the application run mode
    #    Wad.set_mode(:test)
    # @example Query the application's run mode
    #    mode = Wad.run_mode
    ##
    def set_run_mode(mode = nil)
      env_var_name = nil
      if @run_mode.empty?
        raise "too soon to set wad_mode" unless mode.nil?

        # FIXME|to protect each run mode's database from stomping on the
        # others, the datamapper database is stored in a directory
        # path that includes the run mode.
        #
        # * we must call DataMapper.setup() BEFORE we can even define our models...
        # * DataMapper.setup() requires the name of the database
        # * the name of the database requires the run mode
        #
        # ALL of this happens when the script is loaded... LONG before
        # we can process command-line args...

        env_var_name = "#{@name.upcase}_MODE"
        mode = ENV[env_var_name]
        raise "ENV[#{env_var_name}] is MISSING; it must be 'dev', 'test' or 'production'" unless mode.is_str?
      end

      mode = mode.to_s.downcase.strip.to_sym
      mode = :production if mode == :prod
      mode = :development if mode == :dev

      case mode
        when :development, :test, :production, :daemon
          @run_mode = mode
          @_state_root = [home_dir, 'state', host.to_s, name].reduce :+
          @state_dir = _state_root + run_mode.to_s
        when :disabled, :none
          @run_mode = :disabled
          @_state_root = WAD_DIR
          @state_dir = WAD_DIR
        else
          raise "invalid mode: '#{mode.to_s}'"
      end

      # set the environment variable to the canonical run_mode in case
      # anyone wants/needs to inspect it
      ENV[env_var_name] = run_mode.to_s if env_var_name.is_str?

      [_state_root, state_dir].each do |dir|
        raise "invalid state dir, not a dir: '#{dir}'" unless dir.directory?
      end

      @run_mode
    end

    ##
    # Returns the current host's name in canonical form
    # (lowercase with domain information stripped).
    #
    # @return [String]
    #
    # @example Test if we're running on host 'bigmac'
    #     if 'bigmac' == Wad.hostname()
    #
    ##
    def hostname()
      unless @host.is_str?
        hn = ENV['HOSTNAME']
        hn = `/bin/hostname` unless hn.is_str?
        raise "Failed to determine current HOSTNAME" unless hn.is_str?

        hn = hn.downcase.sub(/\..*$/, '').strip
        raise "Failed to determine current HOSTNAME" unless hn.is_str?

        @host = hn.to_sym
      end
      @host
    end

    ##
    # Provide an absolute pathname within the current wad's directory
    # tree when provided relative path components.
    #
    # @param path [String]
    # @return [String]
    #
    # @example Get path to 'public' files
    #    public_dir = Wad.path('public')
    ##
    def path(*path)
      [WAD_DIR, *path].reduce(:+)
    end

    ##
    # Provide an absolute pathname within the wad's public directory tree.
    #
    # @param path [Array<String>]
    # @return [String]
    ##
    def public(*path)
      _public.nil? ? nil : [_public, *path].reduce(:+)
    end

    ##
    # Wad.home(dir, ...)
    #
    ##
    def home(*path)
      [home_dir, *path].reduce(:+)
    end

    ##
    # Provide the absolute path to the directory containing the log files.
    #
    ##
    def log(*path)
      [log_root, *path].reduce(:+)
    end

    ##
    # Provide the absolute path to the root of the state directories.
    #
    # @note  THIS SHOULD BE CONSIDERED AN INTERNAL METHOD!  Use
    #   {Wad#state}.
    #
    # @example Determine database filename
    #    dbfn = Wad.state('database.sqlite')
    ##
    def state_root(*path)
      [_state_root, *path].reduce(:+)
    end

    ##
    # Provide an absolute path within the current Wad's state dir.
    #
    # @note The state directory depends on the current run mode.  This
    #    allows the application to store state during development which
    #    won't overwrite state when the application is run in production
    #    mode.
    #
    # @example Determine database filename
    #    dbfn = Wad.state('database.sqlite')
    ##
    def state(*path)
      [state_dir, *path].reduce(:+)
    end

    def lock_dir()
      unless _lock_dir.directory?
        _lock_dir.mkpath
        raise "unable to create lock directory: '#{_lock_dir}'" unless _lock_dir.directory?
      end
      _lock_dir
    end

    def lock_fname(fname)
      lock_dir + fname
    end

    def expand_variables(str)
      newstr = str.dup
      newstr.gsub!(/\#\{([^}]*?)\}/) do |m|
        name = $1.dup
        if name.is_str?
          name_sym = name.to_sym
          (self.respond_to? name_sym) ? self.send(name_sym) : name
        else
          name
        end
      end
      newstr
    end
  end
end


# class methods for convenient access to the Singleton
module Wad
  def self.libdir()       WadBase.instance.libdir            end
  def self.dir()          WadBase.instance.dir               end
  def self.name()         WadBase.instance.name              end
  def self.home_dir()     WadBase.instance.home_dir          end
  def self.host()         WadBase.instance.host              end
  def self.state_dir()    WadBase.instance.state_dir         end
  def self.run_mode()     WadBase.instance.run_mode          end
  def self.hostname()     WadBase.instance.hostname          end
  def self.set_run_mode(mode = nil) WadBase.instance.set_run_mode(mode) end
  def self.working_dir(*path)       WadBase.instance.working_dir(*path) end
  def self.path(*path)    WadBase.instance.path(*path)       end
  def self.home(*path)    WadBase.instance.home(*path)       end
  def self.settings()     WadBase.instance.settings          end
  def self.log(*path)     WadBase.instance.log(*path)        end
  def self.state(*path)   WadBase.instance.state(*path)      end
  def self.public(*path)  WadBase.instance.public(*path)     end

  def self.lock_dir()     WadBase.instance.lock_dir          end
  def self.lock_fname(*parms)
    WadBase.instance.lock_fname *parms
  end

  def self.expand_variables(*parms)
    WadBase.instance.expand_variables(*parms)
  end
end

require 'wad/log'
require 'wad/exceptions'
require 'wad/settings'
