##
## data-utils/like-hash.rb
##
## Add Hash-like behavior to a class.
##

module LikeHash
  ##
  # Retrieve a specified property from this object.
  #
  # Hash objects provide {Hash#fetch} in order to retrieve the value of
  # a key.  In order to simplify code which accepts either a {Hash} or
  # an {Object}, provide {Object#fetch}.
  #
  # {Object#fetch} uses +respond_to?+ to check if this
  # {Object} will respond to the property.  If so, {Object#fetch}
  # returns the result of +send(property)+.  Otherwise, returns +nil+.
  #
  # @param property [Symbol]
  # @return [nil, Object]
  #
  # @example Fetch the value of a property
  #    id_val = track.fetch(:id)
  ##
  def fetch(prop)
    prop = prop.to_sym if prop.is_a? String

    raise "expected String or Symbol for property, got: '#{prop.to_s}'" unless
      prop.is_a? Symbol

    (self.respond_to? prop) ? self.send(prop) : nil
  end

  alias :'key?' fetch

  ##
  # Provides the +[]+ operator for {Object}.
  #
  # @param prop [String, Symbol]
  # @return [String, Integer, DateTime]
  #
  # @example Get the value of :id property
  #    id_val = track[:id]
  ##
  def [](prop)
    prop = prop.to_sym if prop.is_a? String

    raise "expected String or Symbol for property, got: '#{prop.to_s}'" unless
      prop.is_a? Symbol

    (self.respond_to? prop) ? self.send(prop) : nil
  end

  ##
  # Provides the +[]=+ operator for {Object}.
  #
  # @param prop [String, Symbol]
  # @param value [Object]
  ##
  def []=(prop, val)
    self.send :"#{prop}=", val
  end

  ##
  # Construct a +Hash+ from this object's instance variables.
  #
  # @note Although we use instance_variables to retrieve the names of
  #    the object's instance variables, we actually retrieve the
  #    instance variable's value by invoking the accessor method.
  #    This way we don't bypass anything special that's handled by
  #    the accessors.
  #
  # @param props [Array<String, Symbol>]
  #    (Optional) restrict +Hash+ keys to these properties
  #
  # @return [Hash]
  #
  # @example Construct a Hash from a +track_obj+ obj
  #    track_obj.as_hash
  # @example Construct a Hash from particular properties of +track_obj+
  #    track_obj.as_hash(:title, :composer)
  ##
  def as_hash(*props)
    syms =
        if props.length == 0
            # retrieve the instance variables and chop off the leading '@'.
            # discard any variables whose name begins with '_'
            self.instance_variables.map do |ivar|
                sym = ivar[1...ivar.length]
                sym[0] == '_' ? [] : sym
            end.flatten
        else
            # in this case, we do NOT discard properties whose names begin with '_'
            props.map { |p| p.to_sym }
        end

    hash = {}
    syms.each do |sym|
      hash[sym] = (self.respond_to? sym) ? self.send(sym) : nil
    end

    hash
  end

  ##
  # Set instance variables of this object using the key, value
  # pairs of a Hash.
  #
  # @note For each key in the Hash, if the object has a writer
  #    accessor method whose name matches the key, we call the
  #    writer accessor method.  Otherwise, we fall back to
  #    instance_variable_set. 
  #
  # @note After all of the properties from the +Hash+ have been set,
  #    +self.to_integers!+ is called.
  #
  # @param props [Hash]
  # @return [self]
  ##
  def from_hash!(props = {})
    props.each_pair do |k, v|
        writer = :"#{k}="
        if self.respond_to? writer
            self.send writer, v
        else
            self.instance_variable_set(:"@#{k}", v)
        end        
    end
    self.to_integers!
  end

  ##
  # Update instance variables of this object from the named
  # captures of a MatchData object.
  #
  ##
  def from_matchdata!(md)
    md.names.each do |nm|
      writer = :"#{nm}="
      if self.respond_to? writer
          self.send writer, md[nm]
      else
        isym = :"@#{nm}"
        self.instance_variable_set(isym, md[nm]) if
            self.instance_variable_defined? isym        
      end
    end
    self.to_integers!
  end

  ##
  # Set instance variables of this object using parallel arrays: an
  # array of property names and an array of values.
  #
  # @param props [Array<Symbol>]
  # @param values [Array<Object>]
  # @return [self]
  ##
  def from_arrays!(props, values)
    raise "the properties array and the values array must be the same length" unless
      props.length == values.length
    props.each_with_index do |p, index|
        writer = :"#{p}="
        if self.respond_to? writer
            self.send writer, values[index]
        else
            self.instance_variable_set(:"@#{p}", values[index])
        end
    end
    self.to_integers!
  end

  ##
  # Given a list of properties (keys) of this object, convert the
  # values for each property to an integer.
  #
  # If no properties are specified, to_integers!() looks for a
  # constant named INTEGER_PROPERTIES in the object's class.
  # If this constant exists, those properties have their values
  # converted.
  #
  # @param properties [Array<Symbol>]
  #    (Optional) list of this object's properties to convert to integers
  #
  # @example Convert specified properties' values to integers
  #    process_obj.to_integers! :uid, :pid
  # @example Convert all properties listed in INTEGER_PROPERTIES
  #    process_obj.to_integers!
  ##
  def to_integers!(*properties)
    myclass = self.class

    props =
      if properties.length == 0
        # pull the list of integer properties from the
        # class constant INTEGER_PROPERTIES
        (myclass.constants.include? :INTEGER_PROPERTIES) ?
            myclass.const_get(:INTEGER_PROPERTIES) :
              []
      elsif properties.length == 1 and properties[0].is_a? Array
        properties.first
      else
        properties
      end

    props.each do |p|
      prop = :"@#{p}"
      self.instance_variable_set prop, self.instance_variable_get(prop).to_i
    end

    self
  end

  ##
  # Given an array of names of instance variables, construct an Array of the
  # values of this object's instance variables.
  #
  # @param properties [Array<Symbol>]
  # @return [Array<Object>]
  ##
  def values_at(*properties)
    raise "no properties were specified" if properties.length == 0
    props = (properties.length == 1 and properties[0].is_a? Array) ? properties.first : properties
    props.map { |p| self.instance_variable_get :"@#{p}" }
  end

end
