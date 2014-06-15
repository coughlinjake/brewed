# encoding: utf-8

require 'timeout'

require 'brewed'
require 'brewed/path'

module Brewed
  module Path

    LOCKS_DIR = (::Brewed.home_dir + 'Library/Logs/Locks').freeze

    ##
    # Generate the absolute path to the lockfile for the current process.
    #
    # @return [Pathname]
    ##
    def self.process_lockfn()
      absolute_lockfn "#{File.basename $0}.lock"
    end

    ##
    # Generate an absolute path to a lockfile.
    #
    # All lock files are stored in files whose parent directory
    # is $HOME/Library/Logs/Locks.  $HOME/Library/Logs/Locks
    # should not have any subdirectories.
    #
    # If $HOME/Library/Logs/Locks doesn't exist when `locks_dir`
    # is called, it is created.
    #
    # @param filename [String, Pathname]
    # @return [Pathname]
    ##
    def self.absolute_lockfn(filename)
      unless LOCKS_DIR.directory?
        # Locks directory doesn't exist.  if its parent directory
        # exists, create the Locks dir.  otherwise, raise an exception.
        logsdir = LOCKS_DIR.dirname
        raise "invalid LOCKS_DIR; not a directory: '#{logsdir}'" unless
            logsdir.directory?
        LOCKS_DIR.mkpath
        raise "invalid LOCKS_DIR; failed to create '#{LOCKS_DIR}'" unless
            LOCKS_DIR.directory?
      end
      lockfn = [LOCKS_DIR, filename].reduce(:+)
      raise "ALL lock files have the same parent directory, '#{LOCKS_DIR}'" unless
          lockfn.dirname == LOCKS_DIR
      lockfn
    end

    ##
    # Create an exclusive lock on a specified file.
    #
    # The provided file name *must* be an absolute filename.  If the file exists,
    # this process must have permission to write to the file.  If the file does NOT
    # exist, this process must have permission to create the file.
    #
    # @note The locking mechanism does NOT actually write to the file.
    #
    # If the lock is acquired, a {PathUtils::Lock} is returned.  The lock will remain
    # in effect until either {PathUtils::Lock#release} is called or the
    # {PathUtils::Lock} object is destroyed.
    #
    # If the lock can not be acquired, `nil` is returned.
    #
    # If a block is provided, lock_file yields to the block if the lock is acquired,
    # and the lock is released automatically when the block returns.  The return
    # value from lock_file is whatever the block returned.
    #
    # The only parameters that lock_file handles are `fullpath` and `options[:lock_timeout]`.
    # `:lock_timeout` is removed from `options` as soon as it's used.  `options` is then
    # passed into the block.
    #
    # @param fullpath [String, Pathname]
    #     absolute pathname of the file to lock
    #
    # @param options  [Hash]
    # @option options :lock_timeout [Integer]
    #     timeout in seconds to wait to acquire lock
    #
    # @return [Brewed::Path::Lock]
    ##
    def self.lock_file(fullpath, options = {}, &block)
      Lock.lock fullpath, options, &block
    end

    ##
    ## File-based locking mechanism
    ##
    class Lock
      LOCK_TIMEOUT = 600   # seconds (10 minutes)

      attr_reader :full_path, :fh

      def initialize(handle, fullpath, options = {})
        raise ":handle is required to be an open filehandle" if handle.nil?
        @fh = handle

        raise ":fullpath is required" unless fullpath.is_pathname?
        @full_path = fullpath
      end

      def release()
        unless fh.nil?
          fh.close unless fh.closed?
          @fh = nil
        end
      end

      def locked?()
        fh.nil? ? false : true
      end

      def self.lock(fullpath, options = {}, &block)
        opts = {
            :lock_timeout => LOCK_TIMEOUT,
        }.merge! options

        blockscope = block_given?
        lock = fh = rc = nil
        begin

          # open the file and acquire the exclusive lock
          Timeout::timeout(opts.delete(:lock_timeout)) do
            # Log.Debug "Locking '#{fullpath}'"

            fh = File.open fullpath, File::RDWR|File::CREAT, 0644
            fh.close_on_exec = true

            rc = fh.flock File::LOCK_EX
          end

          raise "flock failed for path '#{fullpath}'" if rc == false or fh.nil?

          # create a Lock object to manage the locked file handle
          lock = Lock.new fh, fullpath, opts

          if blockscope
            rc = yield *opts
            lock.release
            lock = nil
          else
            rc = lock
          end

        rescue Timeout::Error => exp
          Log.Out "EXCEPTION while locking path '#{fullpath}': #{Log.exception_to_string(exp)}"
          lock = nil
          rc   = nil
          raise exp

        ensure
          if blockscope
            if lock.respond_to? :release
              lock.release
              lock = nil
            end
            if fh.respond_to?(:closed) and not fh.closed?
              fh.close
              fh = nil
            end
          end
        end
        rc
      end
    end

  end
end
