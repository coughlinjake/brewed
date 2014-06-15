# encoding: utf-8

require 'pathname'
require 'tempfile'

require 'brewed'

module Brewed
  module Path

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

    ##
    #
    ##
    def self.next_fname_version(fname, firstver = 'AAA')
      fname    = Pathname(fname)
      fndir    = fname.dirname
      fnbase   = (fname.basename fname.extname).to_s
      fnext    = fname.extname.to_s

      ver      = nil
      filename = fname
      while filename.exists?
        ver = (ver ? ver.succ : firstver)
        filename = (fndir + (fnbase + ver)).subext fnext
      end

      filename
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
    # @param fname  [String, Pathname]
    # @return       [String]
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

end
