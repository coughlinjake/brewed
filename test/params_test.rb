#!/usr/bin/env ruby

require_relative './test_helper'

require 'brewed/params'

class FooNoDefaults
  include ::Brewed::Params
  attr_accessor :a, :b, :c, :d, :e, :f
  def initialize(properties = {})
    self.init! properties
  end
end

class FooDefaults
  include ::Brewed::Params
  attr_accessor :a, :b, :c, :d, :e, :f
  def initialize(properties = {})
    self.init! properties,
               :b => { :B => :B },
               :c => 5,
               :f => [ :F ]
  end
end

class Params_Params_Tests < MiniTest::Test
  include ::Brewed::Params

  def test_no_defaults()
    props = {:a => [1], :b => [2], :c => [3]}
    defs  = {}
    new_props = self.params! props, defs
    assert_equal props, new_props, "params! returns props when no defaults provided"
    assert_equal( {}, defs, "params! doesn't modify defs" )

    props[:a].push 2
    new_props[:b].push 1
    assert_equal( {:a => [1, 2], :b => [2], :c => [3]},
                  props,
                  "PROPS, defs, new_props are independent" )

    assert_equal( {:a => [1], :b => [2, 1], :c => [3]},
                  new_props,
                  "props, defs, NEW_PROPS are independent" )

    assert_equal( {}, defs, "props, DEFS, new_props are independent" )

    props = {}
    new_props = self.params! props
    assert_equal props, new_props, "params! returns empty props when empty props provided"

    props[:foo] = :bar
    assert_equal( {}, new_props, "params! returns new empty props so modifying original is safe" )
  end

  def test_just_defaults()
    props = {}
    defs = {:a => 1, :b => [2], :c => 3}
    new_props = self.params!( {}, defs )

    assert_equal( {}, props, "no props just defs so props is still empty" )
    assert_equal defs, new_props, "no props just defs so params! returns defs"

    props[:a] = 1
    defs[:b].push 3
    assert_equal( {:a => 1}, props, "PROPS, defs, new_props are independent" )
    assert_equal( {:a => 1, :b => [2, 3], :c => 3}, defs, "props, DEFS, new_props are independent" )
    assert_equal( {:a => 1, :b => [2], :c => 3}, new_props, "props, defs, NEW_PROPS are independent" )
  end

  def test_params_union_defaults()
    props = {:a => [1], :b => [2], :c => [3]}
    defs  = {:d => [4], :e => [5] }
    new_props = self.params! props, defs
    assert_equal( {:a => [1], :b => [2], :c => [3], :d => [4], :e => [5]}, new_props, "params! union" )

    props[:a].push 2
    defs[:d].push 5
    assert_equal( {:a => [1, 2], :b => [2], :c => [3]}, props, "PROPS, defs, new_props are independent" )
    assert_equal( {:d => [4, 5], :e => [5]}, defs, "props, DEFS, new_props are independent" )
    assert_equal( {:a => [1], :b => [2], :c => [3], :d => [4], :e => [5]}, new_props, "props, defs, NEW_PROPS are independent" )
  end

  def test_params_intersect_defaults()
  end

  def test_params_adamant()
    props = {
        :a => [1],
        :b => [2],
        :c => [3]
    }
    defs  = {
        :a => [:not_used],
        :d => [4],
        :e => { :E => 5 },
        :adamant => {
            :b => [:adamant],
            :f => { :F => :adamant },
        },
    }
    new_props = self.params! props, defs

    #File.open('test1.yml', 'w') { |fh| fh.print Psych.dump(new_props) }

    assert_equal( {:a => [1], :b => [2], :c => [3]}, props, "PROPS, defs, new_props are independent" )

    assert_equal( {
                      :a => [1],
                      :b => [:adamant],
                      :c => [3],
                      :d => [4],
                      :e => { :E => 5 },
                      :f => { :F => :adamant },
                  }, new_props, "params! :adamant over-rides" )

    defs[:adamant][:b].push :not_adamant
    assert_equal( {
                      :a => [1],
                      :b => [:adamant],
                      :c => [3],
                      :d => [4],
                      :e => { :E => 5 },
                      :f => { :F => :adamant },
                  }, new_props, "defs[:adamant] and new_props[:adamant] are independent" )

  end

end
