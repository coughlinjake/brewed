##
## data-utils.rb
##
## Extend Object by providing some useful predicates.
##

class Object

  ##
  # Ask any object whether or not it contains a "string of content".
  #
  # A "string of content" is defined as:
  #   * a Symbol object whose length > 0
  #   * a String object whose length > 0
  #
  # Therefore, NONE of the following is a "string of content":
  #   * true
  #   * false
  #   * nil
  #   * 0, 1, 4, 1.0, 5.3
  #
  # ALL of following are "string of content":
  #   * 'true', :true
  #   * 'false', :false
  #   * 'nil', :nil
  #   * '0', '1', ...
  #
  # @return [true, false]
  #
  # @example Determine whether an env var has been set at all
  #    unless (mode = ENV[var]).is_str?
  #       raise "ENV[#{var}] must be 'dev', 'test' or 'prod'"
  #    end
  ##
  def is_str?
    (self.is_a?(Symbol) or
        (self.is_a?(String) and not self.empty?)) ? true : false
  end

  ##
  # Determine if the current object is a Hash with at least 1 key,value pair.
  #
  # @example Is +var+ a non-empty Hash?
  #    var.is_hash?
  ##
  def is_hash?
    (self.is_a?(Hash) and not self.empty?) ? true : false
  end

  ##
  # Determine if the current object is an Array with at least 1 item.
  #
  # @example Is +var+ a non-empty Array?
  #    var.is_array?
  ##
  def is_array?
    (self.is_a?(Array) and not self.empty?) ? true : false
  end

  ##
  # Returns +true+ if this object is either a String or a Pathname
  # object.
  ##
  def is_pathname?
    (self.is_str? or self.is_a?(Pathname)) ? true : false
  end

  alias :is_path? :is_pathname?

  ##
  # Returns +true+ if the specific object is either +nil+, +0+ or +''+.
  #
  # @return [true, false]
  #
  # @example Use var value if var HAS a value
  #    query_value = name unless name.no_value?
  ##
  def no_value?
    (self.nil? or self == 0 or self == '' or self == [] or self == {}) ? true : false
  end

  ##
  # Returns +true+ if the specific object is NOT +nil+, +0+ or +''+.
  #
  # @return [true, false]
  #
  # @example Use var value if var HAS a value
  #    query_value = name unless name.no_value?
  ##
  def has_value?
    ! no_value?
  end

  ##
  # Return a String which can be safely interpolated either by returning the
  # object itself (because it supports to_s) or by subsituting a descriptive
  # string.
  ##
  def safe_s()
    (self.respond_to? :to_s) ? self.to_s : "OBJECT:#{self.class.to_s}"
  end

end

class String
  EMPTY = ' '.freeze
    
  TRUE_PAT  = %r[(?:^|\b)(?:true|t|yes|y|1)(?:\b|$)]i.freeze
  FALSE_PAT = %r[(?:^|\b)(?:false|f|no|n|0)(?:\b|$)]i.freeze

  ##
  # Convert a String value to a Boolean value.
  #
  # @return [true, false]
  ##
  def to_bool
    return false if self.empty?
    return false if FALSE_PAT.match(self)
    return true
  end

  def safe_s()    self  end

  ##
  # strip! which ALWAYS returns self so it can be used safely in
  # a method call chain.
  ##
  def safe_strip!()         self.strip!; self             end

  ##
  # gsub! which ALWAYS returns self so it can be used safely in
  # a method call chain.
  ##
  def safe_gsub!(pat, repl) self.gsub!(pat, repl); self   end

  ##
  # Strip leading whitespace from beginning of every line in a String.
  #
  # Used for heredocs.
  #
  # @example Strip leading whitespace from heredoc.
  #     puts <<-USAGE.unindent_heredoc
  #       This command does such and such.
  #
  #       Supported options are:
  #         -h         This message
  #     USAGE
  ##
  def unindent_heredoc
    indent = scan(/^[ \t]*(?=\S)/).min.try(:size) || 0
    gsub(/^[ \t]{#{indent}}/, '')
  end
  
  def expand_tabs(tab_stops = 4)
    self.gsub(/([^\t\n]*)\t/) do
      $1 + EMPTY * (tab_stops - ($1.size % tab_stops))
    end
  end
  
  def expand_tabs!(tab_stops = 4)
    self.gsub!(/([^\t\n]*)\t/) do
      $1 + EMPTY * (tab_stops - ($1.size % tab_stops))
    end
  end   
end

class Symbol
  def to_bool()
    # to be false, a Symbol must either be empty or
    # it's symbolically false if it matches FALSE_PAT.
    return false if self.empty?
    return false if String::FALSE_PAT.match(self)
    true
  end

  def safe_s()    self.to_s   end
end

class TrueClass
  STR_TRUE = ':true'.freeze
  def to_bool()   true        end
  def safe_s()    STR_TRUE    end
end

class FalseClass
  STR_FALSE = ':false'.freeze
  def to_bool()   false       end
  def safe_s()    STR_FALSE   end
end

class NilClass
  STR_NIL = ':nil'.freeze
  def to_bool()   false       end
  def safe_s()    STR_NIL     end
end

class Numeric
  ##
  # Convert a number to a Boolean value.
  #
  # @return [true, false]
  ##
  def to_bool()   self.nonzero? ? true : false    end
  def safe_s()    self.to_s   end
end

class Pathname
  ##
  # Return a new Pathname object with the extname set to provided
  # file extension.
  #
  # @param x [String]
  # @return [Pathname]
  #
  # @example Set the file extension to .bar
  #    Pathname.new('foo').with_extname('bar') # => 'foo.bar'
  ##
  def with_extname(x)
    # TODO|rewrite this using Pathname.sub_ext()!
    dirname + ((basename extname).to_s + ((x[0] == '.') ? x : ('.'+x)))
  end
end

module ParamUtils
  ##
  # Use the [key,value] pairs of a Hash to update this object's instance variables.
  # Only instance variables with an assignment accessor are updated.
  #
  # @param hash [Hash]
  ##
  def update_from_hash!(hash)
    hash.each_pair do |k, v|
      writer = :"#{k}="
      self.send writer, v if self.respond_to? writer
    end
  end

  ##
  # Construct a Hash which maps this object's instance variables to their values.
  #
  # @return [Hash]
  ##
  def as_hash(vars = nil)
    hash = {}
    if vars.nil?
      instance_variables.each { |ivar| hash[ivar[1..-1].to_sym] = instance_variable_get ivar }
    else
      vars.each do |sym|
        ivar = :"@#{sym}"
        hash[sym] = instance_variable_get(ivar) if instance_variable_defined? ivar
      end
    end
    hash
  end
end

class Array
  ##
  # Retrieve the named parameters Hash from the optional arguments Array.
  #
  # @example Method with optional Array parameters
  #    def example(*params)
  #      properties = params.named_parameters!
  #      command_line = params.join ' '
  #    end
  #    example 'ls', '-l', {:named => :parameters}
  ##
  def named_parameters!()
    (last.is_a? Hash) ? pop : {}
  end

  ##
  # Return a new list with all Symbols replaced by values from `bindings`.
  #
  # @param bindings [Hash]
  # @param options  [Hash]
  # @return [Array<String>]
  ##
  def replaceholders(bindings, options = {})
    rc = []
    each do |item|
      if item.is_a?(String) and not item.empty?
        rc << item
      elsif bindings[item].has_value?
        rc <<
          case bindings[item]
            when String, Numeric, Symbol, Pathname
              bindings[item].to_s
            when Hash, Array
              bindings[item]
            else
              bindings[item].to_s
          end
      end
    end
    rc.flatten
  end

end

class HashInit < Hash
  ##
  # Verify that every value in a Hash is defined; report all keys with
  # missing values.
  #
  # @param hash [Hash]
  #    the hash to verify
  #
  # @return [Hash]
  #    the hash passed as a parameter is returned unaltered
  ##
  def self.not_missing(hash)
    missing = hash.select { |k, v| v.no_value? }
    raise "values are required but missing for the variables: #{missing.keys.join(', ')}" unless missing.empty?
    hash
  end
end

##
## Utilities shared by all data types.
##
class DataUtils
  ##
  # Perform a deep-clone of an object by calling Marshal.dump() and
  # Marshal.load().
  #
  # @note The only reason this method is in its own class is because I
  #    can never remember the incantation.
  #
  ##
  def self.deep_clone(obj)
    Marshal.load Marshal.dump(obj)
  end
end

