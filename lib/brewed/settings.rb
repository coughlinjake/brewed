# Settings.rb - Application settings using YAML files.
#
# This version constructs a method for each root key of the YAML files.

require 'psych'

require 'brewed'
require 'data-utils/hash'

module Settings
  extend self # singleton

  @_settings_dir = nil
  @_settings = {}
  attr_reader :_settings_dir, :_settings

  ##
  # Load all of the settings files in the specified directory.  If no
  # directory is specified, calls Brewed#settings.
  ##
  def load_dir(dir = nil)
    dir = File.expand_path(dir || Brewed.settings())
    unless dir == @_settings_dir
      raise "settings already loaded from #{_settings_dir}; attempted to re-load settings from #{dir}" unless _settings_dir.nil?
      @_settings_dir = dir
      Dir.glob(File.join(dir, '*.{yml,yaml}')).each do |ymlfn|
        Settings.load! ymlfn
      end
    end
  end

  def method_missing(m, *args, &block)
    load_dir if @_settings.empty?
    raise "#{self.to_s}: no top-level settings key: '#{m.to_s}'" unless self.respond_to? m
    self.send m, *args, &block
  end

  protected

  # This is the main point of entry - we call Settings.load! and provide
  # a name of the file to read as it's argument. We can also pass in some
  # options, but at the moment it's being used to allow per-environment
  # overrides in Rails
  def load!(filename, options = {})
    newsets = Psych.load_file(filename).deep_symbolize

    newsets = newsets[options[:env].to_sym] if options[:env] && newsets[options[:env].to_sym]

    deep_merge!(@_settings, newsets)

    # define an accessor method for each top-level key
    @_settings.each do |k, v|
      define_method(k) do
        v
      end
    end
  end

  # Deep merging of hashes
  # deep_merge by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
  def deep_merge!(target, data)
    merger = proc { |key, v1, v2| (Hash === v1 && Hash === v2) ? v1.merge(v2, &merger) : v2 }
    target.merge! data, &merger
  end

end

=begin MARKDOWN

Given this YAML:

    emails:
      admin:    someadmin@somewhere.net
      support:  support@somewhere.net

    urls:
      search:   http://google.com
      blog:     http://speakmy.name

We load the config:

    Settings.load!("config/appdata/example.yml")

And we query the config:

    Settings.emails[:admin]       # -> someadmin@somewhere.net
    Settings.emails[:support]     # -> support@somewhere.net
    Settings.urls[:search]        # -> http://google.com
    Settings.urls[:blog]          # -> http://speakmy.name

And we can even make the configuration specific to the run mode:

    production:
      emails:
        admin:    someadmin@somewhere.net
        support:  support@somewhere.net

    development: &development
      emails:
        admin:    admin@test.local
        support:  support@test.local

    test:
      <<: *development

To load:

    Settings.load!("#{Rails.root}/config/appdata/env-example.yml", :env => Rails.env)


=end
