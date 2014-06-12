# encoding: utf-8

require 'brewed/env'
require 'brewed/env/dev'

module Brewed
  module Env

    class Ruby < Base
      RUBY_VERSION = '2.1.2'.freeze

      ENV = {
          :GEM_HOME => "#{home}/.rbenv/versions/#{RUBY_VERSION}/lib/ruby/gems/2.1.0",

          :GEM_PATH => [
              "#{home}/.gem/ruby/2.1.0",
              "#{home}/.rbenv/versions/#{RUBY_VERSION}/lib/ruby/gems/2.1.0",
          ],

          :PATH         => [ "#{home}/.rbenv/shims" ],

          :RUBYLIB      => [ "#{usrlocal}/lib/Ruby" ],

          :RUBY_VERSION => RUBY_VERSION,
      }.freeze

      def self.env(*envs)
        Dev.env ENV, *envs
      end

    end
  end
end
