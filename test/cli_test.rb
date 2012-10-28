require 'date'
require 'minitest/autorun'
require 'minitest/autorun'
require 'minitest/pride'
require 'stringio'

require 'timelog/cli'


class CLITest < MiniTest::Unit::TestCase
  def setup
    @stream = StringIO.new
    @client = Timelog::CLI.new(@stream)
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

  # CLI#run raises an ArgumentError if no arguments are provided.
  def test_run_without_arguments
    assert_raises(ArgumentError) { @client.run }
  end
end
