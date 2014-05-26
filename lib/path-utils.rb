# encoding: utf-8

require 'pathname'
require 'tempfile'
require 'timeout'

class PathUtils
  LOCKS_DIR = (Pathname.new(ENV['HOME']) + 'Library/Logs/Locks').freeze

  ##
  # Expand each path to an absolute path and return only those which are
  # directories.
  #
  # @param dirs [Array<Pathname, String>]
  # @return [Array<Pathname>]
  ##
  def self.expand_dirs(*dirs)
    dirs.flatten.
        map { |dir| (dir.is_a? Pathname) ? dir : Pathname.new(dir) }.
          map { |dir| dir.expand_path }.
            select { |dir| dir.directory? }
  end

  ##
  # Search a list of paths for a specific filename.
  #
  # Returns the absolute path for the first filename found.
  #
  # @param fname [Pathname, String]
  # @param paths [Array<Pathname, String>]
  # @return [Pathname, nil]
  ##
  def self.first_in_path(fname, *paths)
    fname = (fname.is_a? Pathname) ? fname : Pathname.new(fname)
    paths.each do |p|
      fullpath = ((p.is_a? Pathname) ? p : Pathname.new(p)) + fname
      return fullpath if fullpath.file?
    end
    nil
  end
  
  def next_fname_version(fname, firstver = 'AAA')
      fname    = Pathname.new fname
      fndir    = fname.dirname
      fnfname  = (fname.basename fname.extname).to_s
      fnext    = fname.extname.to_s
      ver      = nil
      filename = fname
      while filename.exists?
        ver = (ver ? ver.succ : firstver)
        filename = (fndir + (base + suffix)).subext fnext
      end
      filename
  end
 

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
  # Construct a "safe" filename from the provided filename.
  #
  # +fname+ can be just a filename, a full pathname or a
  # relative path.  Before generating the safe filename,
  # +safe_fname+ reduces +fname+ to just its basename without
  # a file extension.  Once this basename has been converted to
  # a "safe" version, the original directory and file extension
  # are restored.
  #
  # @param fname [String, Pathname]
  #     the full path, relative path or filename to make "safe"
  #
  # @return [Pathname]
  #     the safe result
  #
  # @example Make a "safe" filename of a class name
  #     PathUtils.safe_fname Pathname
  #     => pathname
  #
  # @example Make a "safe" filename from a path
  #     PathUtils.safe_fname '../../this is a test.bar'
  #     => '../../this_is_a_test.bar'
  ##
  def self.safe_fname(fname)
    return '_' if fname == '.'
    return '__' if fname == '..'

    newfn = Pathname.new fname.to_s
    dir = newfn.dirname
    fext = newfn.extname

    # reduce to base filename with no extension
    newfn = newfn.basename fext

    newfn = newfn.to_s.downcase
    newfn.gsub! /\s+/, '_'
    newfn.gsub! /[^-a-zA-Z0-9_.;+~]/, ''
    newfn.gsub! /_+/, '_'

    dir + (newfn + fext)
  end

  ##
  # Generate a tempory filename.
  #
  # The :for option specifies the existing filename which the temporary file is intended
  # to replace.
  #
  # @param options [Hash]
  # @option options :cleanup  [true, false]
  #    delete the file automatically upon close (default: false)
  #
  # @option options :for      [String, Pathname]
  #    the absolute filename containing the content to be replaced
  #
  # @option options :dir      [String, Pathname]  (Optional; use :for! instead)
  # @option options :basename [String, Pathname]  (Optional; use :for! instead)
  # @option options :fext     [String]            (Optional; use :for! instead)
  #
  # @option options :fname_prepend      [String]
  # @option options :fname_append       [String]
  #
  # @return [nil, Pathname]
  ##
  def self.temp_filename(options = {})
    if options[:for].is_pathname?
      dir      = Pathname.new(options[:for]).expand_path
      fext     = dir.extname
      basename = dir.basename dir.extname
      dir      = dir.dirname
    else
      dir      = options[:dir]      || Dir.tmp
      basename = options[:basename] || 'temp_filename'
      fext     = options[:fext]     || 'tmp'
    end

    missing =
      {:dir => dir, :basename => basename, :fext => fext}.each_pair.select { |opt, val| val.nil? }
    raise "missing required options: #{missing.map { |pair| pair[0].to_s }.join(', ')}" if
        missing.length > 0

    basename = basename.to_s
    basename = "#{options[:fname_prepend]}#{basename}" if options[:fname_prepend].is_str?
    basename = "#{basename}#{options[:fname_append]}"  if options[:fname_append].is_str?

    meth = (options[:cleanup] == true) ? :new : :create
    file = ::Tempfile.send meth, [basename, fext.to_s], dir.to_s

    newpath = (file.respond_to? :path) ? Pathname.new(file.path.to_s) : nil

    if options[:cleanup] == true and file.respond_to?(:close!)
      file.close!
    elsif file.respond_to? :close
      file.close
    end

    newpath
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
  # @return [PathUtils::Lock]
  ##
  def self.lock_file(fullpath, options = {}, &block)
    PathUtils::Lock.lock fullpath, options, &block
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

  ##
  # Determine whether a given object can be used as a filesystem path.
  #
  # @note DEPRECATED!  `DataUtils` adds `is_pathname?` to `Object`.
  #
  # @param obj [String, Pathname]
  # @return [true, false]
  ##
  def self.is_pathname?(obj)
    (obj.is_str? or obj.is_a?(Pathname)) ? true : false
  end

  ##
  # Given a fully-qualified path, a relative path or just a filename,
  # return just the basename without a file extension.
  #
  # @param fname [String, Pathname]
  # @return [String]
  #
  # @example Basename of relative path
  #    PathUtils.just_basename '../../foo_cockles.bar'
  #    => 'foo_cockles'
  ##
  def self.just_basename(fname)
    p = Pathname(fname)
    (p.basename p.extname).to_s
  end
end
