require File.dirname(__FILE__) + '/../spec_helper'
require 'mspec/utils/script'
require 'mspec/runner/mspec'
require 'mspec/runner/filters'
require 'mspec/runner/actions/filter'
require 'mspec/runner/actions/debug'
require 'mspec/runner/actions/gdb'

describe MSpecScript, ".config" do
  it "returns a Hash" do
    MSpecScript.config.should be_kind_of(Hash)
  end
end

describe MSpecScript, ".set" do
  it "sets the config hash key, value" do
    MSpecScript.set :a, 10
    MSpecScript.config[:a].should == 10
  end
end

describe MSpecScript, "#config" do
  it "returns the MSpecScript config hash" do
    MSpecScript.set :b, 5
    MSpecScript.new.config[:b].should == 5
  end

  it "returns the MSpecScript config hash from subclasses" do
    class MSSClass < MSpecScript; end
    MSpecScript.set :b, 5
    MSSClass.new.config[:b].should == 5
  end
end

describe MSpecScript, ".main" do
  before :all do
    @verbose = $VERBOSE
    $VERBOSE = nil
  end

  after :all do
    $VERBOSE = @verbose
  end

  before :each do
    @version = RUBY_VERSION
    @script = mock("MSpecScript", :null_object => true)
    MSpecScript.stub!(:new).and_return(@script)
  end

  after :each do
    Object.const_set :RUBY_VERSION, @version
  end

  it "attempts to load a config file based on RUBY_VERSION" do
    Object.const_set :RUBY_VERSION, "1.8.9"
    version = "1.8.mspec"
    @script.should_receive(:load).with(version)
    MSpecScript.main
  end
end

describe MSpecScript, ".main" do
  before :each do
    @script = mock("MSpecScript", :null_object => true)
    MSpecScript.stub!(:new).and_return(@script)
  end

  it "creates an instance of MSpecScript" do
    MSpecScript.should_receive(:new).and_return(@script)
    MSpecScript.main
  end

  it "attempts to load the 'default.mspec' script" do
    @script.should_receive(:load).with('default.mspec')
    MSpecScript.main
  end

  it "attempts to load the '~/.mspecrc' script" do
    @script.should_receive(:load).with('~/.mspecrc')
    MSpecScript.main
  end

  it "calls the #options method on the script" do
    @script.should_receive(:options)
    MSpecScript.main
  end

  it "calls the #signals method on the script" do
    @script.should_receive(:signals)
    MSpecScript.main
  end

  it "calls the #register method on the script" do
    @script.should_receive(:register)
    MSpecScript.main
  end

  it "calls the #run method on the script" do
    @script.should_receive(:run)
    MSpecScript.main
  end
end

describe MSpecScript, "#initialize" do
  before :each do
    @config = MSpecScript.new.config
  end

  it "sets the default config values" do
    @config[:tags_dir].should   == 'spec/tags'
    @config[:formatter].should  == DottedFormatter
    @config[:includes].should   == []
    @config[:excludes].should   == []
    @config[:patterns].should   == []
    @config[:xpatterns].should  == []
    @config[:tags].should       == []
    @config[:xtags].should      == []
    @config[:atags].should      == []
    @config[:astrings].should   == []
    @config[:abort].should      == true
    @config[:config_ext].should == '.mspec'
  end
end

describe MSpecScript, "#load" do
  before :each do
    File.stub!(:exist?).and_return(false)
    @script = MSpecScript.new
    @file = "default.mspec"
    @base = "default"
  end

  it "attempts to locate the file through the expanded path name" do
    File.should_receive(:expand_path).with(@file).and_return(@file)
    File.should_receive(:exist?).with(@file).and_return(true)
    Kernel.should_receive(:load).with(@file).and_return(:loaded)
    @script.load(@file).should == :loaded
  end

  it "appends config[:config_ext] to the name and attempts to locate the file through the expanded path name" do
    File.should_receive(:expand_path).with(@base).and_return(@base)
    File.should_receive(:expand_path).with(@file).and_return(@file)
    File.should_receive(:exist?).with(@base).and_return(false)
    File.should_receive(:exist?).with(@file).and_return(true)
    Kernel.should_receive(:load).with(@file).and_return(:loaded)
    @script.load(@base).should == :loaded
  end

  it "attemps to locate the file in '.'" do
    path = File.join ".", @file
    File.should_receive(:exist?).with(path).and_return(true)
    Kernel.should_receive(:load).with(path).and_return(:loaded)
    @script.load(@file).should == :loaded
  end

  it "appends config[:config_ext] to the name and attempts to locate the file in '.'" do
    path = File.join ".", @file
    File.should_receive(:exist?).with(path).and_return(true)
    Kernel.should_receive(:load).with(path).and_return(:loaded)
    @script.load(@base).should == :loaded
  end

  it "attemps to locate the file in 'spec'" do
    path = File.join "spec", @file
    File.should_receive(:exist?).with(path).and_return(true)
    Kernel.should_receive(:load).with(path).and_return(:loaded)
    @script.load(@file).should == :loaded
  end

  it "appends config[:config_ext] to the name and attempts to locate the file in 'spec'" do
    path = File.join "spec", @file
    File.should_receive(:exist?).with(path).and_return(true)
    Kernel.should_receive(:load).with(path).and_return(:loaded)
    @script.load(@base).should == :loaded
  end
end

describe MSpecScript, "#register" do
  before :each do
    @script = MSpecScript.new

    @formatter = mock("formatter", :null_object => true)
    @script.config[:formatter] = @formatter
  end

  it "creates and registers the formatter" do
    @formatter.should_receive(:new).and_return(@formatter)
    @formatter.should_receive(:register)
    @script.register
  end

  it "does not register the formatter if config[:formatter] is nil" do
    @script.config[:formatter] = nil
    @script.register
  end
end

describe MSpecScript, "#register" do
  before :each do
    @script = MSpecScript.new

    @formatter = mock("formatter", :null_object => true)
    @script.config[:formatter] = @formatter

    @filter = mock("filter")
    @filter.should_receive(:register)

    @ary = ["some", "spec"]
  end

  it "creates and registers a MatchFilter for include specs" do
    MatchFilter.should_receive(:new).with(:include, *@ary).and_return(@filter)
    @script.config[:includes] = @ary
    @script.register
  end

  it "creates and registers a MatchFilter for excluded specs" do
    MatchFilter.should_receive(:new).with(:exclude, *@ary).and_return(@filter)
    @script.config[:excludes] = @ary
    @script.register
  end

  it "creates and registers a RegexpFilter for include specs" do
    RegexpFilter.should_receive(:new).with(:include, *@ary).and_return(@filter)
    @script.config[:patterns] = @ary
    @script.register
  end

  it "creates and registers a RegexpFilter for excluded specs" do
    RegexpFilter.should_receive(:new).with(:exclude, *@ary).and_return(@filter)
    @script.config[:xpatterns] = @ary
    @script.register
  end

  it "creates and registers a TagFilter for include specs" do
    TagFilter.should_receive(:new).with(:include, *@ary).and_return(@filter)
    @script.config[:tags] = @ary
    @script.register
  end

  it "creates and registers a TagFilter for excluded specs" do
    TagFilter.should_receive(:new).with(:exclude, *@ary).and_return(@filter)
    @script.config[:xtags] = @ary
    @script.register
  end

  it "creates and registers a ProfileFilter for include specs" do
    ProfileFilter.should_receive(:new).with(:include, *@ary).and_return(@filter)
    @script.config[:profiles] = @ary
    @script.register
  end

  it "creates and registers a ProfileFilter for excluded specs" do
    ProfileFilter.should_receive(:new).with(:exclude, *@ary).and_return(@filter)
    @script.config[:xprofiles] = @ary
    @script.register
  end

  it "creates and registers a DebugAction for excluded specs" do
    @script.config[:atags] = ["some"]
    @script.config[:astrings] = ["string"]
    DebugAction.should_receive(:new).with(["some"], ["string"]).and_return(@filter)
    @script.config[:debugger] = true
    @script.register
  end

  it "creates and registers a GdbAction for excluded specs" do
    @script.config[:atags] = ["some"]
    @script.config[:astrings] = ["string"]
    GdbAction.should_receive(:new).with(["some"], ["string"]).and_return(@filter)
    @script.config[:gdb] = true
    @script.register
  end
end

describe MSpecScript, "#signals" do
  before :each do
    @script = MSpecScript.new
    @abort = @script.config[:abort]
  end

  after :each do
    @script.config[:abort] = @abort
  end

  it "traps the INT signal if config[:abort] is true" do
    Signal.should_receive(:trap).with("INT")
    @script.config[:abort] = true
    @script.signals
  end

  it "does not trap the INT signal if config[:abort] is not true" do
    Signal.should_not_receive(:trap).with("INT")
    @script.config[:abort] = false
    @script.signals
  end
end

describe MSpecScript, "#entries" do
  before :each do
    @script = MSpecScript.new
  end

  it "returns the pattern in an array if it is a file" do
    File.should_receive(:expand_path).with("file").and_return("file")
    File.should_receive(:file?).with("file").and_return(true)
    @script.entries("file").should == ["file"]
  end

  it "returns Dir['pattern/**/*_spec.rb'] if pattern is a directory" do
    File.should_receive(:expand_path).with("dir").and_return("dir")
    File.should_receive(:file?).with("dir").and_return(false)
    File.should_receive(:directory?).with("dir").and_return(true)
    Dir.should_receive(:[]).with("dir/**/*_spec.rb").and_return(["dir1", "dir2"])
    @script.entries("dir").should == ["dir1", "dir2"]
  end

  it "returns Dir[pattern] if pattern is neither a file nor a directory" do
    File.should_receive(:expand_path).with("pattern").and_return("pattern")
    File.should_receive(:file?).with("pattern").and_return(false)
    File.should_receive(:directory?).with("pattern").and_return(false)
    Dir.should_receive(:[]).with("pattern").and_return(["file1", "file2"])
    @script.entries("pattern").should == ["file1", "file2"]
  end
end

describe MSpecScript, "#files" do
  before :each do
    @script = MSpecScript.new
  end

  it "accumlates the values returned by #entries" do
    @script.should_receive(:entries).and_return(["file1"], ["file2"])
    @script.files(["a", "b"]).should == ["file1", "file2"]
  end

  it "strips a leading '^' and removes the values returned by #entries" do
    @script.should_receive(:entries).and_return(["file1"], ["file2"], ["file1"])
    @script.files(["a", "b", "^a"]).should == ["file2"]
  end

  it "processes the array elements in order" do
    @script.should_receive(:entries).and_return(["file1"], ["file1"], ["file2"])
    @script.files(["^a", "a", "b"]).should == ["file1", "file2"]
  end
end
