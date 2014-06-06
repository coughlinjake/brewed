# encoding: utf-8

# = Brewed.rb
#
# == Environment Variables
#
# HOSTNAME
# : name of host application is executing on
#
# *BREWED_NAME*_MODE
# : `dev`, `test`, `production`
#
# == Application State
#
# State directory:
#
#      [HOME]/state/[HOSTNAME]/[BREWED_NAME]/[BREWED_MODE]
#

require 'singleton'
require 'pathname'

module Brewed

  class BrewedBase
    include Singleton

    LIBDIR = Pathname.new(__FILE__).dirname.expand_path.freeze
    REAL_LIBDIR = Pathname.new(__FILE__).expand_path.realpath.dirname.freeze

    BINSTR = 'bin'.freeze
    LIBSTR = 'lib'.freeze

    LOCAL_LIB = (Pathname.new(Dir.home) + 'usr/local/lib/Ruby').freeze

    ##
    # Determine the brewed directory.
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
    def self.find_brewed_dir()
      dir = (ENV['BREWED_DIR'] ? Pathname.new(ENV['BREWED_DIR']) : Pathname.getwd).realpath
      while (not dir.root?) and (not (dir + BINSTR).directory?) and (not (dir + LIBSTR).directory?)
        dir = dir.dirname
      end
      raise "FAILED to locate project root starting from '#{Pathname.getwd}'" if dir.root?
      dir
    end

    BREWED_DIR = find_brewed_dir.freeze

    def self.add_load_path(dir)
      fulldir = Pathname.new(dir).expand_path
      fulldir = fulldir.dirname unless fulldir.directory?
      $LOAD_PATH.unshift(fulldir) unless $LOAD_PATH.include? fulldir
    end

    def self.bootstrap()
      # add the real lib dir first so that brewed local files can over-ride global files
      add_load_path LOCAL_LIB if LOCAL_LIB.directory?
      add_load_path REAL_LIBDIR
      add_load_path LIBDIR
      add_load_path (BREWED_DIR+LIBSTR)
    end

    def self.brewed_relative(path)
      fullpath = Pathname.new(path).expand_path
      fullpath.relative_path_from BREWED_DIR
    end

    ##
    #
    # @param submodule [String,Pathname]
    #    the absolute path to a Ruby module filename.
    #    +$LOAD_PATH+ will be updated to contain +submodule+'s dirname.
    ##
    def self.require_sub_modules(submodule)
      submod_path = brewed_relative submodule

      # remove both the dirname and the file extension from this filename
      # 'app/models/tv.rb' => 'tv'
      submod_base = submod_path.basename submod_path.extname

      # 'app/models/tv.rb' => 'app/models'
      submod_dir = submod_path.dirname

      mod_root = submod_dir + submod_base
      #puts "requiring #{mod_root.to_s}"
      require mod_root.to_s

      # find all filenames matching the glob "#{submod_dir}/#{submod_base}/*.rb"
      Dir.glob(BREWED_DIR + mod_root + '*.{rb,rbo}').
          map { |mabs| Pathname.new(mabs.chomp(File.extname(mabs))).relative_path_from(BREWED_DIR) }.
          uniq.each do |modname|
        #puts "requiring #{modname.to_s}"
        require modname.to_s
      end
    end
  end

  ##
  ## Bootstrap the brewed's execution/load environment.
  ##
  BrewedBase.bootstrap

  require 'data-utils'

  class BrewedBase
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

      # @note Brewed assumes:
      #    * it's located somewhere in lib directory tree,
      #    * the root of that **lib** tree is a directory named "lib"
      #    * there are no intermediate directories between "lib" and brewed.rb also named "lib"
      #    * the parent of "lib" is the root of the brewed
      #
      # therefore, work our way backward back up the directory tree until we
      # reach a directory with a child dir named "lib"
      @dir = BREWED_DIR
      @name = BREWED_DIR.basename.to_s.downcase

      # set the host name
      hostname

      @home_dir = Pathname.new Dir.home

      @_log_root = @_log_filename = @_working_dir = @_public = nil

      if name == 'ruby'
        # loading system application from /usr/local/bin
        # "global" settings dir
        @run_mode = :disabled

        @settings = [BREWED_DIR, @host.is_str? ? @host : [], $PROGRAM_NAME].flatten.reduce :+

        @_log_root = home_dir + 'Library/Logs'
        raise "invalid log_root: '#{_log_root}" unless _log_root.directory?

        @_state_root = nil
        @state_dir = nil

      else
        # loading from private application directory structure:
        # ../@name/
        #    @name/public
        #    @name/settings
        @_public = BREWED_DIR + 'public'
        @settings = BREWED_DIR + 'settings'

        # @note set_run_mode also sets state directories
        set_run_mode
      end

      @_lock_dir = @state_dir + 'LOCKS'
    end

    ##
    # Return an absolute path within the working directory.
    #
    # The working directory is determined:
    #   * value of BREWED_WORKING_DIR env var
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
    # Provide the absolute path to this Brewed's lib dir.
    #
    # @return [String]
    ##
    def libdir()
      LIBDIR
    end

    ##
    # Sets the current application run mode.
    #
    # Use {Brewed#run_mode} to query the application's run mode.
    #
    # @note During initialization (probably before the application code starts),
    #    the run mode is set from the value of the application's run mode
    #    environment variable.  The variable name is constructed by uppercasing
    #    the application name (see {Brewed#name}) and appending '_MODE'.
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
    #    Brewed.set_mode(:test)
    # @example Query the application's run mode
    #    mode = Brewed.run_mode
    ##
    def set_run_mode(mode = nil)
      env_var_name = nil
      if @run_mode.empty?
        raise "too soon to set brewed_mode" unless mode.nil?

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
          @_state_root = BREWED_DIR
          @state_dir = BREWED_DIR
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
    #     if 'bigmac' == Brewed.hostname()
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
    # Provide an absolute pathname within the current brewed's directory
    # tree when provided relative path components.
    #
    # @param path [String]
    # @return [String]
    #
    # @example Get path to 'public' files
    #    public_dir = Brewed.path('public')
    ##
    def path(*path)
      [BREWED_DIR, *path].reduce(:+)
    end

    ##
    # Provide an absolute pathname within the brewed's public directory tree.
    #
    # @param path [Array<String>]
    # @return [String]
    ##
    def public(*path)
      _public.nil? ? nil : [_public, *path].reduce(:+)
    end

    ##
    # Brewed.home(dir, ...)
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
    #   {Brewed#state}.
    #
    # @example Determine database filename
    #    dbfn = Brewed.state('database.sqlite')
    ##
    def state_root(*path)
      [_state_root, *path].reduce(:+)
    end

    ##
    # Provide an absolute path within the current Brewed's state dir.
    #
    # @note The state directory depends on the current run mode.  This
    #    allows the application to store state during development which
    #    won't overwrite state when the application is run in production
    #    mode.
    #
    # @example Determine database filename
    #    dbfn = Brewed.state('database.sqlite')
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
module Brewed
  def self.libdir()       BrewedBase.instance.libdir            end
  def self.dir()          BrewedBase.instance.dir               end
  def self.name()         BrewedBase.instance.name              end
  def self.home_dir()     BrewedBase.instance.home_dir          end
  def self.host()         BrewedBase.instance.host              end
  def self.state_dir()    BrewedBase.instance.state_dir         end
  def self.run_mode()     BrewedBase.instance.run_mode          end
  def self.hostname()     BrewedBase.instance.hostname          end
  def self.set_run_mode(mode = nil) BrewedBase.instance.set_run_mode(mode) end
  def self.working_dir(*path)       BrewedBase.instance.working_dir(*path) end
  def self.path(*path)    BrewedBase.instance.path(*path)       end
  def self.home(*path)    BrewedBase.instance.home(*path)       end
  def self.settings()     BrewedBase.instance.settings          end
  def self.log(*path)     BrewedBase.instance.log(*path)        end
  def self.state(*path)   BrewedBase.instance.state(*path)      end
  def self.public(*path)  BrewedBase.instance.public(*path)     end

  def self.lock_dir()     BrewedBase.instance.lock_dir          end
  def self.lock_fname(*parms)
    BrewedBase.instance.lock_fname *parms
  end

  def self.expand_variables(*parms)
    BrewedBase.instance.expand_variables(*parms)
  end
end

require 'brewed/version'
require 'brewed/log'
require 'brewed/exceptions'
require 'brewed/settings'
