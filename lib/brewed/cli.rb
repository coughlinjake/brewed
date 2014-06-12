# encoding: utf-8

#
# ==CLI Notes==
#
# * Applications must subclass Brewed::Cli::Base
#   * If The subclass over-rides initialize(), initialize() MUST call super().
#
# * The application's entry point must be _application_run().  The base class's
#   application_run() will invoke _application_run() after all resources have been
#   aquired.
#
#   * If the application requires an exclusive lock, define the method
#     application_lock().  It should return the absolute filename for the lock file.
#     An exclusive write lock will be obtained by application_run() BEFORE
#     _application_run() is called, and the lock will automatically be removed
#     when application_run() returns.
#
# * application_run() catches all exceptions.  Before calling abort(), application_run()
#   will check for a application_fail() method can invoke it.
#
# * If no exception occurs, application_run() checks for application_success() and
#   calls it before application_run() returns and the application terminates normally.
#

require 'pathname'

require 'path-utils'

require 'brewed/settings'
require 'brewed/env/ruby'

module Brewed

  module CLI

    ##
    ## Base class for Command Line Scripts
    ##
    class Base

      attr_reader   :class_name
      attr_accessor :args, :argv, :env

      def initialize()
        @class_name = self.class.to_s

        @args = {}
        @argv = []

        @env =
            Brewed::Env::Ruby.project_env :PATH => [
                Brewed.path('bin'),
            ]

        raise "#{class_name} is REQUIRED to provide a :usage method" unless
            self.respond_to? :usage

        raise "#{class_name} is REQUIRED to provide a :_run method" unless
            self.respond_to? :_application_run

        self
      end

      ##
      # Parse the command line into a Hash of arguments.
      #
      # A very simple parser to convert the provided +argv+ Array into a Hash.
      # The resulting Hash is stored in the instance variable +args+.
      #
      # If either of the keys 'help' or 'usage' have values before parse_args()
      # returns, parse_args() will NOT return because it will call +usage+.
      #
      # @note Be aware that +argv+ is drained directly.
      #
      # @param argv [Array<String>]
      #    usually ARGV but can be any array with the same format
      ##
      def parse_args(argv)
        @args ||= nil
        raise "#{class_name}.initialize failed to call super!" unless
          args.is_a?(Hash)

        #
        # if this CLI has boolean arguments which can immediately
        # precede the non-option arguments (ie those arguments which
        # don't begin with '--'), those booleans need to be declared.
        # otherwise when parsing the boolean argument, we'll mistake
        # the boolean as an option with a value:
        #
        #    foo.rb --boolean firstnonoption
        #
        # becomes args = {:boolean => 'firstnonoption'}.
        #
        booleans = {}
        booleans = Hash[*(boolean_args.map { |a| [a,1] }.flatten)] if
            self.respond_to? :boolean_args

        skipped = []
        while argv.length > 0 do
          unless argv[0] =~ /^--?/
            skipped.push argv.shift

          else
            # shift the argument name out of argv
            argname = argv.shift.sub(/^--?/, '').downcase
            raise ArgumentError, "expected: --ARGNAME; got: '#{argname.inspect}'" unless
                argname.is_str?

            # strip trailing '-' then convert remaining '-' to '_'
            argsym = argname.sub(/-+$/, '').gsub(/-+/, '_').to_sym

            if booleans[argsym] or (argv.length < 1) or (argv[0] =~ /^--?/)
              # a boolean argument whose value is false when the argument ends with '-'
              args[argsym] = (argname =~ /-$/) ? false : true
            else
              # named argument
              args[argsym] = argv.shift
            end
          end
        end

        self.argv = skipped || []

        usage if args[:help] or args[:usage]
      end

      ##
      # Run the CLI application.
      #
      # If this object responds to :application_lock, then application_lock() will
      # be called and we will obtain an exclusive write lock on the returned filename.
      #
      # The application's actual entry point _application_run() will be invoked by
      # application_run().
      ##
      def application_run()
        # we return a Bash exit value which means that rc == 0 is success
        # and anything else is failure.  assume we fail then prove otherwise.
        rc = 1
        begin
          if self.respond_to? :application_lock
            applock = self.application_lock
            Log.Debug("[LOCKING '#{applock}'...]") {
              PathUtils.lock_file(applock) do
                rc = _application_run
              end
            }
          else
            rc = _application_run
          end

        rescue => exp
          msg = Log.exception_to_string exp
          Log.Out msg

          rc = 1
          if self.respond_to? :application_fail
            m   = self.application_fail msg
            msg = m unless m.nil?
          else
            msg += "\n\nexit status: FAILED!"
          end

          abort "EXCEPTION #{exp.class.to_s}: #{exp.message}"
        end

        # output the application's success message or our default
        msg =
          if rc == 0
            (self.respond_to? :application_success) ?
                self.application_success : "exit status: SUCCESS!"
          else
            "exit status: FAILED!"
          end

        Log.Out msg

        rc
      end

      def self.cmdline(argv)
        app = self.new
        app.parse_args argv
        app.application_run
      end
    end

  end
end
