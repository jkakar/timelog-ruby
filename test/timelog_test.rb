require 'minitest/autorun'
require 'minitest/pride'
require 'stringio'

require 'timelog/timelog'


class TimelogTest < MiniTest::Unit::TestCase

  # Timelog#record_activity writes the specified description to the time log
  # stream, along with the current date and time.
  def test_record_activity
    stream = StringIO.new
    timelog = Timelog::Timelog.new(stream)
    timelog.record_activity('Writing a test')
    assert_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}: Writing a test\n/,
                 stream.string)
  end

end
