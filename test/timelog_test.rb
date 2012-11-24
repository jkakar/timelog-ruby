require 'time'
require 'minitest/unit'
require 'stringio'
require 'tempfile'

require 'timelog/timelog'

class LoadTimelogTest < MiniTest::Unit::TestCase
  def setup
    @stream = Tempfile.new('timelog')
  end

  def teardown
    @stream.close
    @stream.unlink
  end

  # Timelog#load_timelog loads activities from the stream.  This is
  # essentially a no-op if the stream is empty.
  def test_load_stream_with_empty_stream
    timelog = Timelog.load_stream(@stream)
    assert_equal([], timelog.activities)
  end

  # Timelog#load_timelog loads activities from the stream.
  def test_load_stream_with_activities
    @stream.write("2012-01-31 10:52: Arrived\n" <<
                  "2012-01-31 10:59: Writing a test\n")
    @stream.rewind
    timelog = Timelog.load_stream(@stream)
    assert_equal([{:start_time => Time.new(2012, 1, 31, 10, 52),
                    :end_time => Time.new(2012, 1, 31, 10, 59),
                    :description => 'Writing a test'}],
                 timelog.activities)
  end

  # Timelog#load_timelog treats empty lines as day separators.  The start time
  # is reset each time an empty line is encountered.
  def test_load_stream_with_empty_lines
    @stream.write("2012-01-29 23:12: Arrived\n" <<
                  "2012-01-29 23:18: Writing a test\n" <<
                  "\n" <<
                  "2012-01-31 10:52: Arrived\n" <<
                  "2012-01-31 10:59: Writing another test\n")
    @stream.rewind
    timelog = Timelog.load_stream(@stream)
    assert_equal([{:start_time => Time.new(2012, 1, 29, 23, 12),
                    :end_time => Time.new(2012, 1, 29, 23, 18),
                    :description => 'Writing a test'},
                  {:start_time => Time.new(2012, 1, 31, 10, 52),
                    :end_time => Time.new(2012, 1, 31, 10, 59),
                    :description => 'Writing another test'}],
                 timelog.activities)
  end

  # Timelog#load_timelog ignores malformed lines.
  def test_load_stream_with_malformed_lines
    @stream.write("This isn't a valid activity line\n")
    @stream.rewind
    timelog = Timelog.load_stream(@stream)
    assert_equal([], timelog.activities)
  end
end

class TimelogTest < MiniTest::Unit::TestCase
  def setup
    @stream = Tempfile.new('timelog')
    @timelog = Timelog::Timelog.new([], @stream)
  end

  def teardown
    @stream.close
    @stream.unlink
  end

  # Timelog::Timelog#record_activity writes the specified description to the
  # activity stream, along with the current date and time.
  def test_record_activity
    @timelog.record_activity('Writing a test')
    @stream.rewind
    assert_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}: Writing a test\n/,
                 @stream.read)
  end

  # Timelog::Timelog#record_activity formats the activity timestamp in
  # YYYY-MM-DD HH:MM format.  An explicit Time timestamp can optionally be
  # provided.
  def test_record_activity_formats_date
    timestamp = Time.new(2012, 1, 31, 10, 59)
    @timelog.record_activity('Writing a test', timestamp)
    @stream.rewind
    assert_equal("2012-01-31 10:59: Writing a test\n", @stream.read)
  end

  # Timelog::Timelog#record_activity writes a blank line to separate
  # activities that occur on different days.  A new days starts at 4am.
  def test_record_activity_detects_day_boundaries
    yesterday = Time.new(2012, 1, 31, 3, 59) # Yesterday at 3:59am
    @timelog.record_activity('Writing a test', yesterday)
    today = Time.new(2012, 1, 31, 4) # Today at 4:00am
    @timelog.record_activity('Writing another test', today)
    @stream.rewind
    assert_equal("2012-01-31 03:59: Writing a test\n" <<
                 "\n" <<
                 "2012-01-31 04:00: Writing another test\n",
                 @stream.read)
  end

  # Timelog::Timelog#record_activity writes a blank line to separate
  # activities that occur on different days.  Day change detection works
  # correctly when more than 24 hours has passed since the last activity.
  def test_record_activity_detects_multiple_day_boundaries
    yesterday = Time.new(2012, 1, 29, 12) # Two days ago at 12:00pm
    @timelog.record_activity('Writing a test', yesterday)
    today = Time.new(2012, 1, 31, 15) # Today at 3:00pm
    @timelog.record_activity('Writing another test', today)
    @stream.rewind
    assert_equal("2012-01-29 12:00: Writing a test\n" <<
                 "\n" <<
                 "2012-01-31 15:00: Writing another test\n",
                 @stream.read)
  end

  # Timelog::Timelog#record_activity groups activities that occur on the same
  # day together in the activity file, one per line.
  def test_record_activity_groups_activities_on_the_same_day
    today1 = Time.new(2012, 1, 31, 14, 56) # Today at 2:56pm
    @timelog.record_activity('Arrived', today1)
    today2 = Time.new(2012, 1, 31, 15, 0)  # Today at 3:00pm
    @timelog.record_activity('Writing a test', today2)
    today3 = Time.new(2012, 1, 31, 15, 5)  # Today at 3:05pm
    @timelog.record_activity('Writing another test', today3)
    @stream.rewind
    assert_equal("2012-01-31 14:56: Arrived\n" <<
                 "2012-01-31 15:00: Writing a test\n" <<
                 "2012-01-31 15:05: Writing another test\n",
                 @stream.read)
  end
end
