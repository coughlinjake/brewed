
require 'brewed'

module Brewed
  module HashSymbolize

    ##
    # Recursively symbolize the keys of all Hashes in the provided object.
    #
    # @note This symbolize method is the interface for symbolizing objects.
    #    The remaining methods should be considered private.
    #
    # @param value [Object]
    # @return a new object with all Hash keys symbolized
    #
    # @example Symbolize the keys of a Hash
    #     HashSymbolize.symbolize { 'a' => 'A', 'b' => 'B' }
    #       #=> { :a => 'A', :b => 'B'
    ##
    def self.symbolize(obj)
      method = obj.class.to_s.downcase.to_sym
      self.respond_to?(method) ? self.send(method, obj) : obj
    end

    def self.hash(hash)
      hash.inject({}) do |result, (key, value)|
        # Symbolize the key string if it responds to to_sym
        sym_key = key.to_sym rescue key

        result[sym_key] =  _recurse_ value

        result
      end
    end

    def self.array(ary)
      ary.map { |v| _recurse_ v }
    end

    def self._recurse_(value)
      (value.is_a?(Enumerable) and not value.is_a?(String)) ? symbolize(value) : value
    end

  end
end
