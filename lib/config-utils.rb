# config-utils.rb
#
# In the class that you're configuring:
#
#    class MyClass
#       def init(*args, &block)
#         config = ConfigStruct.block_to_hash(block)
#         # process your config ...
#       end
#    end
# 
# To configure MyClass:
#
#    MyClass.new.init do |c|
#      c.some = "config"
#      c.info = "goes here"
#    end

require 'ostruct'

class ConfigStruct < OpenStruct
  def self.block_to_hash(block=nil)
    config = self.new
    if block
      block.call(config)
      config.to_hash
    else
      {}
    end
  end

  def to_hash
    @table
  end
end