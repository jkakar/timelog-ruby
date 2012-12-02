require 'date'
require 'minitest/unit'
require 'stringio'

require 'timelog/cli'


class CLITest < MiniTest::Unit::TestCase
  def setup
    @stream = StringIO.new
    @output = StringIO.new
    @client = Timelog::CLI.new(@stream, @output)
  end

  # Timeout::CLI#run writes the specified activity to the stream and prints
  # the daily report to the screen.
  def test_run_with_first_activity
    @client.run('Writing a test')
    assert_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}: Writing a test\n/,
                 @stream.string)
    assert_equal("Time spent working:   0 h 00 min\n" <<
                 "Time spent slacking:  0 h 00 min\n" <<
                 "Time left at work:    8 h 00 min\n",
                 @output.string)
  end

  # Timeout::CLI#run raises a UsageError if -h or --help arguments are
  # specified.
  def test_run_with_help_option
    assert_raises(Timelog::UsageError) { @client.run('-h') }
    assert_raises(Timelog::UsageError) { @client.run('--help') }
  end

  # Timeout::CLI#run displays today's activities when no arguments are
  # specified.
  def test_run_without_arguments
    @client.run
    assert_equal("Time spent working:   0 h 00 min\n" <<
                 "Time spent slacking:  0 h 00 min\n" <<
                 "Time left at work:    8 h 00 min\n",
                 @output.string)
  end
end


class UsageError < MiniTest::Unit::TestCase
  # Converting a Timeout::UsageError to a string yield help text to display to
  # a user.
  def test_to_s
    client = Timelog::CLI.new(StringIO.new, StringIO.new)
    begin
      client.run('-h')
    rescue Timelog::UsageError => error
      assert_equal(
        "Usage: turn [options]\n" <<
        "    -h, --help                       Display this screen\n",
        error.to_s)
    end
  end
end
