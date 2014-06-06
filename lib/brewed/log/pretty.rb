# encoding: utf-8

module Brewed
  ##
  ## == PrettyPrint ==
  ##
  class PrettyPrint
    def pretty(obj, opts = {})
      meth =
          case obj
            when Hash then :_pretty_hash
            else raise ArgumentError, "expected Hash, got: #{obj.inspect}"
          end
      self.send meth, obj, opts
    end

    def _pretty_hash(hash, options = {})
      # subtract 5 from value width to account for ' => ' and the enclosing '|'
      val_width = (options[:value_width] || 60) - 5

      # convert all keys to strings with leading ':'
      # we need to keep the original key so we can dereference the
      # original hash.
      max_width = 0
      hash.keys.each { |k| max_width = (k.length > max_width) ? k.length : max_width }

      # add 3 to the width to account for leading ':'
      max_width += 3

      fmt = "| %- #{max_width}s => |%s|"

      output = ''
      hash.keys.sort.each do |k|
        valstr = hash[k].to_s
        # truncate the value if it's too long
        outstr = (valstr.length <= val_width) ? valstr : (valstr[0...val_width] + DOTDOTDOT)
        output << sprintf(fmt, ":#{k}", outstr)
      end.join(NL)

      output
    end
  end
end
