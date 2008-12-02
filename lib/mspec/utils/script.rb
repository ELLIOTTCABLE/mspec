require 'mspec/runner/formatters/dotted'

# MSpecScript provides a skeleton for all the MSpec runner scripts.

class MSpecScript
  def self.config
    @config ||= {
      :path => ['.', 'spec'],
      :config_ext => '.mspec'
    }
  end

  def self.set(key, value)
    config[key] = value
  end

  def initialize
    config[:formatter] = nil
    config[:includes]  = []
    config[:excludes]  = []
    config[:patterns]  = []
    config[:xpatterns] = []
    config[:tags]      = []
    config[:xtags]     = []
    config[:profiles]  = []
    config[:xprofiles] = []
    config[:atags]     = []
    config[:astrings]  = []
    config[:ltags]     = []
    config[:abort]     = true
  end

  def config
    MSpecScript.config
  end

  def load(target)
    names = [target]
    unless target[-6..-1] == config[:config_ext]
      names << target + config[:config_ext]
    end

    names.each do |name|
      return Kernel.load(name) if File.exist?(File.expand_path(name))

      config[:path].each do |dir|
        file = File.join dir, name
        return Kernel.load(file) if File.exist? file
      end
    end
  end

  def load_default
    if Object.const_defined?(:RUBY_ENGINE)
      engine = RUBY_ENGINE
    else
      engine = 'ruby'
    end
    version = RUBY_VERSION.split('.')[0,2].join('.')

    load "#{engine}.#{version}.mspec"
  end

  def register
    if config[:formatter].nil?
      config[:formatter] = @files.size < 50 ? DottedFormatter : FileFormatter
    end
    config[:formatter].new(config[:output]).register if config[:formatter]

    MatchFilter.new(:include, *config[:includes]).register    unless config[:includes].empty?
    MatchFilter.new(:exclude, *config[:excludes]).register    unless config[:excludes].empty?
    RegexpFilter.new(:include, *config[:patterns]).register   unless config[:patterns].empty?
    RegexpFilter.new(:exclude, *config[:xpatterns]).register  unless config[:xpatterns].empty?
    TagFilter.new(:include, *config[:tags]).register          unless config[:tags].empty?
    TagFilter.new(:exclude, *config[:xtags]).register         unless config[:xtags].empty?
    ProfileFilter.new(:include, *config[:profiles]).register  unless config[:profiles].empty?
    ProfileFilter.new(:exclude, *config[:xprofiles]).register unless config[:xprofiles].empty?

    DebugAction.new(config[:atags], config[:astrings]).register if config[:debugger]
    GdbAction.new(config[:atags], config[:astrings]).register   if config[:gdb]
  end

  def signals
    if config[:abort]
      Signal.trap "INT" do
        puts "\nProcess aborted!"
        exit! 1
      end
    end
  end

  def entries(pattern)
    expanded = File.expand_path(pattern)
    return [pattern] if File.file?(expanded)
    return Dir[pattern+"/**/*_spec.rb"].sort if File.directory?(expanded)
    Dir[pattern]
  end

  def files(list)
    list.inject([]) do |files, item|
      if item[0] == ?^
        files -= entries(item[1..-1])
      else
        files += entries(item)
      end
      files
    end
  end

  def self.main
    $VERBOSE = nil unless ENV['OUTPUT_WARNINGS']
    script = new
    script.load_default
    script.load '~/.mspecrc'
    script.options
    script.signals
    script.register
    script.run
  end
end
