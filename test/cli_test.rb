require 'date'
require 'minitest/autorun'
require 'minitest/pride'
require 'stringio'

require 'timelog/cli'


class CLITest < MiniTest::Unit::TestCase
  def setup
    @stream = StringIO.new
    @output = StringIO.new
    @client = Timelog::CLI.new(@stream, @output)
  end

  # CLI#run writes the specified activity to the stream.
  def test_run_with_first_activity
    @client.run('Writing a test')
    assert_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}: Writing a test\n/,
                 @stream.string)
  end

  # CLI#run raises a UsageError if -h or --help arguments are specified.
  def test_run_with_help_option
    assert_raises(Timelog::UsageError) { @client.run('-h') }
    assert_raises(Timelog::UsageError) { @client.run('--help') }
  end

  # CLI#run displays today's activities when no arguments are specified.
  def test_run_without_arguments
    @client.run
    assert_equal('', @output.string)
  end
end


class UsageError < MiniTest::Unit::TestCase
  # Converting a UsageError to a string yield help text to display to a user.
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
