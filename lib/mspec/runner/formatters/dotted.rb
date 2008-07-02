require 'mspec/expectations/expectations'
require 'mspec/runner/actions/timer'
require 'mspec/runner/actions/tally'

class DottedFormatter
  attr_reader :timer, :tally

  def initialize(out=nil)
    @states = []
    if out.nil?
      @out = $stdout
    else
      @out = File.open out, "w"
    end
  end

  def register
    @timer = TimerAction.new
    @timer.register
    @tally = TallyAction.new
    @tally.register
    @counter = @tally.counter

    MSpec.register :after, self
    MSpec.register :finish, self
  end

  def after(state)
    unless state.exception?
      print "."
    else
      @states << state
      print failure?(state) ? "F" : "E"
    end
  end

  def finish
    print "\n"
    count = 0
    @states.each do |state|
      state.exceptions.each do |msg, exc|
        outcome = failure?(state) ? "FAILED" : "ERROR"
        print "\n#{count += 1})\n#{state.description} #{outcome}\n"
        print "#{exc.class.name} occurred during: #{msg}\n" if msg
        print message(exc)
        print "\n"
        print backtrace(exc)
        print "\n"
      end
    end
    print "\n#{@timer.format}\n\n#{@tally.format}\n"
  end

  def print(*args)
    @out.print(*args)
  end
end
