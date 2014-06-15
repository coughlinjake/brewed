# encoding: utf-8

require 'brewed'
require 'brewed/path'

module Brewed
  module Path

    UNDER    = '_'.freeze
    UNDERNEW = '_new_'.freeze
    UNDEROLD = '_original_'.freeze

    ##
    # Safely replace a file by writing new content to a temporary file, renaming
    # the original to a different temporary filename, then renaming the new
    # content's temporary file to the original filename.
    #
    # @param full_fname [String,Pathname]
    # @param options [Hash]
    # @option options :empty_ok [true, false]
    #    don't raise an exception when new content is not generated
    # @return [true, false]
    #
    ##
    def self.safe_replace(full_fname, options = {})
      raise "PathUtils.safe_replace requires a block" unless block_given?

      full_fname = Pathname.new(full_fname).expand_path
      rc = false
      Log.Debug("[PathUtils.safe_replace: #{full_fname}]") {

        err_new_content = "\tnew content wasn't generated"
        err_orig_pres   =
            full_fname.file? ? "\toriginal preserved in: '#{full_fname}'" : "\tno original existed"

        # we need 2 filenames:
        #   1. temp store_fname where we'll dump the new YAML
        #   2. temp old store_fname to rename current store_fname to move it out of the way
        #      so we can rename temp store_fname to store_fname
        tmp_content = nil
        tmp_old     = nil
        begin
          tmp_content =
              ::Brewed::Path.temp_filename :cleanup => true,
                                           :for     => full_fname,
                                           :fname_prepend => UNDER,
                                           :fname_append  => UNDERNEW
          Log.Debug "tmp_content: '#{tmp_content}'"

          tmp_old =
              ::Brewed::Path.temp_filename :cleanup => true,
                                           :for     => full_fname,
                                           :fname_prepend => UNDER,
                                           :fname_append  => UNDEROLD
          Log.Debug "tmp_old: '#{tmp_old}'"

          # the block will create the new content in the file tmp_content
          begin
            yield tmp_content
          rescue => exp
            Log.Debug "EXCEPTION while generating content for '#{full_fname}'"
            raise
          end

          err_new_content = "\tnew content is in: '#{tmp_content}'"

          # verify new content written successfully
          unless tmp_content.file?
            Log.Debug "tmp_content: no content generated; missing file '#{tmp_content}'"
            raise "new content is missing; file not found: '#{tmp_content}'\n#{err_orig_pres}" unless
                options[:empty_ok]
            return true
          end

          if tmp_content.size == 0
            Log.Debug "tmp_content: file size == 0: '#{tmp_content}'"
            tmp_content.unlink
            raise "new content is empty; removed zero-length file: '#{tmp_content}'\n#{err_orig_pres}" unless
                options[:empty_ok]
            return true
          end

          Log.Debug "NEW CONTENT: '#{tmp_content}'"

          if full_fname.file?
            # rename original to tmp_old
            Log.Debug "RENAMING ORIGINAL:\n\tORIGINAL: #{full_fname}\n\ttmp_old: #{tmp_old}"
            raise "unable to rename original\n#{err_new_content}\n#{err_orig_pres}" unless
                full_fname.rename(tmp_old) == 0
            err_orig_pres = "\toriginal preserved in '#{tmp_old}'"
          else
            Log.Debug "ORIGINAL not found so NEW CONTENT immediately promoted"
          end

          # rename new content as original filename
          Log.Debug "RENAMING NEW:\n\ttmp_content: #{tmp_content}\n\toriginal: #{full_fname}"
          raise "installing new content failed\n#{err_new_content}\n#{err_orig_pres}" unless
              tmp_content.rename(full_fname) == 0

          err_new_content = "new content is in: '#{full_fname}'"

          # delete original content
          if tmp_old.file?
            Log.Debug "DELETING original: #{tmp_old}"
            tmp_old.unlink
            err_orig_pres   = "original has been removed"
          end

          Log.Debug "SUCCESSFULLY REPLACED '#{full_fname}'"
          rc = true

        rescue => exp
          Fail.Error "EXCEPTION while generating '#{full_fname}':\n",
                     err_new_content, "\n",
                     err_orig_pres, "\n",
                     Log.exception_to_string(exp)
          raise
        end
      }

      rc
    end

  end
end
