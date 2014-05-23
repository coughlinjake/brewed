
##
## MutableHash
##
class MutableHash < Hash
  def initialize(hash)
    # use either a MutableHash as is or a deep clone of a regular Hash.
    # then copy its values into this MutableHash object
    h = (hash.is_a? MutableHash) ? hash : self.class.deep_clone(hash)
    h.each_pair { |k, v| self[k] = v }
    self
  end
  def self.deep_clone(obj)
    Marshal.load Marshal.dump(obj)
  end
end

module Params

  module ClassMethods
    ##
    # Add defaults to an existing set of parameters.
    #
    # Note that neither `params` or `defaults` will be altered in any
    # way unless either is a `MutableHash`.
    #
    # The goal is to reduce the number of objects created for each method
    # call.  When `params` is a Hash, the Hash is deep cloned into a
    # MutableHash (which is completely independent of the original).
    # However, when `params` is already a MutableHash, it is updated
    # in-place.  Values are only cloned when they are not already
    # independent of their source.
    #
    # Generally, only values originating in the `defaults` Hash will be
    # cloned and they're cloned only when they're used.
    #
    # When a default value is used, if the default value
    # responds_to? :call, it is assumed to be a dynamic value.  The
    # default value's :call method is invoked and its result is used.
    # **NOTE:** This result is assumed to be independent of its source
    # and will NOT be cloned.
    #
    # @param params [Hash, MutableHash]
    # @param defaults [Hash, MutableHash]
    # @return [MutableHash]
    ##
    def params!(params, defaults = {})
      # since params already contains the values we'll ultimately want in
      # our objects, make sure it's a MutableHash.
      p = (params.is_a? MutableHash) ? params : MutableHash.new(params)

      # we'll deep-clone only those default values we wind up using.
      # it's unlikely that defaults will be Mutable already...
      defaults_immutable = (defaults.is_a? MutableHash) ? true : false

      adamant = {}
      if defaults.key? :adamant
        adamant = defaults[:adamant]
        adamant = MutableHash.new adamant unless defaults_immutable
      end

      defaults.each_pair do |key, default|

        if key == :adamant or adamant.key?(key)
          # adamant value is ALWAYS used
          next

        elsif p[key].nil?
          # no param => initialize with default value
          p[key] = _clone_default default, defaults_immutable

        # param has value; no adamant value.  however, if both param value
        # and default value are Hashes, merge default value into param value.
        elsif p[key].is_hash? and default.is_hash?
          phash = p[key]
          default.each_pair do |k, v|
            phash[k] = _clone_default(v, defaults_immutable) if not v.nil? and phash[k].nil?
          end
        end
      end

      # we ensured that adamant's values were mutable above
      adamant.each_pair { |key, value| p[key] = value }

      p
    end

    ##
    # Given a value from provided defaults, return an equivalent value which
    # can be placed independently into another object.
    #
    # Essentially, if the value responds to :call, invoke the value's :call
    # method and return the result AS IS.  Otherwise, if the value originates
    # in a MutableHash (highly unlikely), return the value AS IS.  Otherwise,
    # deep clone the value.
    #
    # @param obj [Object]
    # @param mutable_source [true, false]
    # @return [Object]
    ##
    def _clone_default(obj, mutable_source = false)
      if obj.respond_to? :call      then obj.call
      elsif mutable_source          then obj
      elsif obj.is_a? MutableHash   then obj
      else                          MutableHash.deep_clone(obj)
      end
    end

    ##
    # Initialize this object's instance variables using the provided parameters
    # and any defaults.
    #
    # @note `init!` only initializes instance variables for which a read
    #    or a write accessor exists.  In other words, given a [var, value] pair,
    #    the following MUST be true in order for the instance variable corresponding
    #    to `var` to be initialized:
    #
    #    self.respond_to?( :var ) or self.respond_to?( :"#{var.to_s}=" )
    #
    # @note `init!` passes both of its parameters to `params!`, and the result
    #    is used to initialize this object.  See `params!`.
    #
    # @param params   [Hash, MutableHash]
    # @param defaults [Hash, MutableHash]
    # @return         [self]
    ##
    def init!(params, defaults = {})
      p = self.params! params, defaults
      p.each_pair do |var, val|
        self[var] = val if self.respond_to?(var.to_sym) or self.respond_to?(:"#{var.to_s}=")
      end
      self
    end

    ##
    # Initialize this object's instance variables from ALL of the provided
    # params and defaults.
    #
    # Unlike, `init!`, `init_all!` initializes an instance variable for
    # every [var, value], regardless of read or write accessors.
    ##
    def init_all!(params, defaults = {})
      p = self.params! params, defaults
      p.each_pair { |var, val| self[var] = val }
      self
    end
  end

  def self.included(base)
    base.send :include, ClassMethods
    base.extend ClassMethods
  end

  # PARAMS_MODIFIABLE = :__PARAMS_MODIFIABLE.freeze

  def [](property)
    propsym = property.to_sym
    (self.respond_to? propsym) ? self.send(propsym) : nil
  end

  def []=(property, value)
    setter = :"#{property}="
    if self.respond_to? setter
      self.send setter, value
    else
      instance_variable_set :"@#{property}", value
    end
  end

end