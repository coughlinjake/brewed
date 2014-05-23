##
## data-utils/array.rb
##

class Array
  ##
  # Construct a new Array by yielding every item in this Array
  # to the block and collecting only the block return values
  # which aren't nil or false.
  #
  # @return [Array]
  ##
  def map_values
    raise "a block is required" unless block_given?
    values = []
    self.each do |item|
      v = yield item
      values << v unless v.nil? or v == false
    end
    values
  end

  ##
  # Construct a new Array by calling a Proc on every item
  # of this Array and collecting only the block return
  # values which aren't nil or false.
  #
  # @return [Array]
  ##
  def map_values(&b)
    values = []
    self.each do |item|
      v = b.call item
      values << v unless v.nil? or v == false
    end
    values
  end
end

