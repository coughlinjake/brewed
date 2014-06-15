##
## data/hash.rb
##

require 'brewed'
require 'brewed/data/deep_symbolize'

class Hash
  include ::Brewed::DeepSymbolizable

  ##
  # Alias keys to names
  ##
  alias :names keys

  ##
  # Check whether this Hash has the specified key.  If the key exists in this
  # Hash, returns true if the key's value IS a value.
  #
  # @note The following conditions are NOT considered to be values:
  #     1. nil?
  #     2. 0
  #     3. ''
  #
  # @param key [String, Symbol]
  # @return [true,false]
  #
  # @example Determine if parameter was provided
  #    name = (options.key_has_value? :name) ? options[:name] : DEFAULT_NAME
  ##
  def key_has_value?(key)
    return false unless self.key? key
    value = self.fetch key
    return false if value.nil? or value == 0
    return false if value.is_a?(String) and not value.empty?
    true
  end

  ##
  # Given a list of properties (keys) of this {Hash}, convert the
  # value for each to an integer.
  #
  # @note This feature is also implemented in LikeHash, which can
  #    be mixed into a class withtout requiring the methods
  #    implemented here.
  #
  # @param properties [Array<Symbol>]
  # @return [self]
  #
  # @example Convert specified string values to integer values
  #    hash = { :zero => '0', :name => 'foo', :max => '1000' }
  #    hash.to_integers! :zero, :max
  #      # [=>] hash == { :zero => 0, :name => 'foo', :max => 1000 }
  ##
  def to_integers!(*properties)
    props = (properties.length == 1 and properties[0].is_a?(Array)) ? properties.shift : properties
    props.each { |p| self[p] = self[p].to_i }
    self
  end

  ##
  # Given a list of properties (keys) of this {Hash}, convert the
  # value for each to a boolean (ie true, false).
  #
  # @note This feature is also implemented in LikeHash, which can
  #    be mixed into a class withtout requiring the methods
  #    implemented here.
  #
  # @param properties [Array<Symbol>]
  # @return [self]
  #
  # @example Convert specified string values to boolean values
  #    hash = { :zero => '0', :name => 'foo', :max => 1 }
  #    hash.to_boolean! :zero, :max
  #      # [=>] hash == { :zero => false, :name => 'foo', :max => true }
  ##
  def to_boolean!(*properties)
    props = (properties.length == 1 and properties[0].is_a?(Array)) ? properties.shift : properties
    props.each do |p|
      self[p] =
        case self[p]
          when true, false            then self[p]
          when 0, '0', 'false', 'no'  then false
          when 1, '1', 'true', 'yes'  then true
          else false
        end
    end
    self
  end

  ##
  # Create a new {Hash} object from an {Array} of keys and an {Array} of values.
  #
  # @param keys [Array<String, Symbol>]
  #    an Array containing the Hash keys to set
  #
  # @param vals [Array<Object>]
  #    an Array containing the values to set
  #
  # @return [Hash]
  #
  # @example Create a Hash from 2 parallel Arrays
  #    h = Hash.new_by_assoc [:a, :b, :c], ['A', 'B', 'C']
  #      # [=>] h == { :a => 'A', :b => 'B', :c => 'C' }
  ##
  def self.new_by_assoc(keys, vals)
    raise "# of keys (#{keys.length}) != # of values (#{vals.length})" unless
      keys.length == vals.length

    h = {}
    h.merge! Hash[ keys.zip( vals.respond_to?(:each) ? vals : [vals] ) ]

    h
  end

  ##
  # Construct a Hash from an object's instance variables.
  #
  # @note This feature is also implemented in LikeHash, which can
  #    be mixed into a class withtout requiring the methods
  #    implemented here.
  #
  # @param obj [Object]
  #    the object which originates the +Hash+ keys/values
  #
  # @param props [Array]
  #    (Optional) restrict +Hash+ keys to these properties
  #
  # @return [Hash]
  #
  # @example Construct a Hash from a track_obj obj
  #    hash = Hash.new_from_object(track_obj)
  ##
  def self.new_from_object(obj, props = nil)
    ivars =
        if props.nil?
          obj.instance_variables
        elsif props.is_a? Array
          props.collect { |p| "@#{p}".to_sym }
        else
          raise "expected an Array of properties"
        end

    hash = {}
    ivars.each do |ivar|
      hsym = ivar.to_s
      # strip off the freaking '@'
      hash[hsym[1...hsym.length].to_sym] = obj.instance_variable_get(ivar)
    end

    hash
  end
end
