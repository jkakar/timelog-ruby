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

  # CLI#start writes the specified activity to the stream.
  def test_start_with_first_activity
    @client.start('Writing a test')
    assert_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}: Writing a test\n/,
                 @stream.string)
  end

  # CLI#start raises an ArgumentError if no arguments are provided.
  def test_start_without_arguments
    assert_raises(ArgumentError) { @client.start() }
  end
end
