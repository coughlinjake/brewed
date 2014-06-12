# encoding: utf-8

require 'data-utils'

module Brewed
  module Env

    def self.set_environment(*params)   Brewed::Env::Base.set_environment *params  end
    def self.env(*params)               Brewed::Env::Base.env *params              end
    def self.project_env(*params)       Brewed::Env::Base.project_env *params      end
    def self.set_global(*params)        Brewed::Env::Base.set_global *params       end
    def self.global(*params)            Brewed::Env::Base.global *params           end
    def self.home()                     Brewed::Env::Base.home                     end
    def self.path()                     Brewed::Env::Base.path                     end

    def self.which(exe, pathstr = nil)  Brewed::Env::Base.which exe, pathstr       end

    ##
    ## =======================
    ## == Brewed::Env::Base ==
    ## =======================
    ##
    class Base
      HOME     = (ENV['HOME']    || '/Users/jakec').freeze
      DROPBOX  = (ENV['UNISON']  || "#{HOME}/UNISON").freeze

      UNISON   = "#{HOME}/UNISON".freeze
      USRLOCAL = "#{UNISON}/usr/local".freeze

      ENV      = {
          :GTK_PATH    => %w{ /usr/local/lib/gtk-2.0 },

          :GDK_PIXBUF_MODULEDIR => %w{ /usr/local/lib/gdk-pixbuf-2.0/2.10.0/loaders },

          :LANG        => 'en_US.UTF-8',
          :LANGVAR     => 'en_US.UTF-8',
          :LC_CTYPE    => 'en_US.UTF-8',

          :PYTHONPATH  => %w{ /usr/local/lib/python2.7/site-packages },

          :RUN_SH      => "#{USRLOCAL}/bin/run.sh",
      }

      @global_vars = {
          :HOME     => HOME,
          :DROPBOX  => DROPBOX,
          :UNISON   => UNISON,
          :USRLOCAL => USRLOCAL
      }
      class << self; attr_reader :global_vars end

      ##
      # Update ENV from the var, value pairs of the provided Hash.
      #
      # @param env  [Hash]   the new var, value pairs to put into the ENV
      # @return     [Hash]   the previous var, value pairs from the ENV
      ##
      def self.set_environment(env)
        prev_env = {}
        mash(env).each_pair do |var, val|
          ## !!!
          ## FIXME|which ENV are we altering here?  the global or our constant?
          ## !!!
          prev_env[var] = ENV[var]
          ENV[var] = val
        end
        prev_env
      end

      ##
      # Search a path string for the first executable and return it as
      # an absolute path.
      #
      # @param exe      [String]
      # @param pathstr  [nil,String]
      # @return         [nil, String]
      ##
      def self.which(exe, pathstr = nil)
        pathstr ||= ENV['PATH']
        pathstr.split(':').each do |p|
          x = Pathname.new(p) + exe
          return x.to_s if x.executable?
        end
        nil
      end

      ##
      # Combine base environment with project-scoped environment such that project-scoped
      # variables have priority.
      #
      # @param penv [Hash]      project-scoped environment
      # @return     [Hash]
      ##
      def self.project_env(penv = {})
        self.env penv
      end

      ##
      # Combine provided environments with the base env.
      #
      # @param envs [Array<Hash>]
      # @return [Hash]
      ##
      def self.env(*envs)
        base = compose mash(ENV),
                       :HOME        => home,
                       :DROPBOX     => dropbox,
                       :PATH        => path,
                       :PERL5LIB    => [ "#{usrlocal}/etc", "#{usrlocal}/lib/Perl" ],
                       :USRLOCAL    => usrlocal,
                       :USRLOCALBIN => "#{usrlocal}/etc:#{usrlocal}/lib/Perl:#{usrlocal}/bin"
        compose base, *envs
      end

      ##
      # Set the value of a global variable.  Pass `nil` to delete the global variable.
      #
      # Returns the new value of the variable.
      #
      # @param var    [Symbol]
      # @param val    [nil, Object]
      # @return       [Object]
      ##
      def self.set_global(var, val)
        if val == nil
          Brewed::Env::Base.global_vars.delete var
        else
          Brewed::Env::Base.global_vars[var] = val
        end
      end

      ##
      # Get the value of a global variable.
      #
      # @param var  [Symbol]
      # @return     [Object]
      ##
      def self.global(var)
        Brewed::Env::Base.global_vars[var]
      end

      ##
      # Convenience methods for global variables that are used frequently.
      ##
      def self.home()     global :HOME      end
      def self.dropbox()  global :DROPBOX   end
      def self.unison()   global :UNISON    end
      def self.usrlocal() global :USRLOCAL  end

      ##
      # If a global value has been set for :PATH, return the global value.
      # Otherwise, dynamically construct PATH.
      ##
      def self.path()
        global(:PATH) ||
            [
              "#{home}/bin",
              "#{usrlocal}/bin",
              '/usr/local/perl-5.18.2/bin',
              '/usr/local/perl-5.16.1/bin',
              '/usr/local/sw/bin',
              '/usr/local/git/bin',
              '/usr/local/bin',
              '/usr/local/sbin',
              '/usr/bin',
              '/bin',
              '/usr/sbin',
              '/sbin',
              ]
      end

      ##
      # Mash all variables with Array values to a String by joining the Array items with ':',
      # and convert all variable names to String.
      #
      # @note Does NOT alter the provided Hash; a new Hash is constructed.
      #
      # @note Array values may contain items which are Arrays.  Each top-level Array value
      #     is flattened before its items are joined.
      #
      # @param env    [Hash]
      # @return       [Hash]
      ##
      def self.mash(env)
        vars = env.keys
        vars.inject({}) do |acc, var|
          val = env[var]
          acc[var.to_s] = (val.is_a? Array) ? val.flatten.join(':') : val
          acc
        end
      end

      ##
      # Hash composition by mashing any number of Hashes into an initial Hash.
      #
      # @note Only the :base Hash is altered.  If the base Hash shouldn't be altered,
      #     CALLER is responsible for cloning the base BEFORE calling compose().
      #
      #     compose is usually invoked as:
      #
      #          compose mash(ENV), hash2, hash3
      #
      #     It is safe to call compose() without first cloning the constant ENV because
      #     mash() NEVER alters any of its parameters.  mash() always constructs an
      #     entirely new Hash.
      #
      # @param base   [Hash]
      # @param envs   [Hash, Array<Hash>]
      # @return       [Hash]
      ##
      def self.compose(base, *envs)
        [*envs].inject(base) do |acc, env|
          env.each_pair do |var, val|
            # NOTE: the result BEGINS with val
            val = [ val, *acc[var.to_s] ].flatten.join(':') if val.is_a? Array
            acc[var.to_s] = val
          end
          acc
        end
      end
    end

  end
end
