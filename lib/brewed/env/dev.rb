# encoding: utf-8

require 'brewed/env'

module Brewed
  module Env

    class Dev < Base
      ENV = {
          :ARCHFLAGS     => '-arch x86_64 -arch i386',
          :DEVELOPER_DIR => '/Applications/Xcode.app/Contents/Developer',
      }.freeze

      def self.env(*envs)
        super ENV, *envs
      end
    end

  end
end
