
module Brewed
  module Meta
    ##
    # Mostly here to substantiate Brewed::Meta.
    ##
    def self.available?()
      true
    end

    ##
    # Test whether a class has been defined or not.
    #
    # @param class_name [String, Symbol]
    # @return           [true, false]
    #
    # @example Determine if the Foo class has been defined:
    #    ::Brewed::Meta.class_exists? :Foo
    ##
    def class_exists?(class_name)
      klass = Module.const_get(class_name)
      return klass.is_a?(Class)
    rescue NameError
      return false
    end

  end
end

##
# Allow a module M to include all of the methods of another module AM so that
# whenever module M is included in a class, the class gets both M's and AM's
# methods.
#
# @param mod  [Module]
#
# @example Include all module A's method in module B:
#     module B
#        include_module_methods A
#     end
##
class Module
  def include_module_methods(mod)
    mod.singleton_methods.each do |m|
      (class << self; self; end).send :define_method, m, mod.method(m).to_proc
    end
  end
end
