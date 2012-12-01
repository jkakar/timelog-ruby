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

  # Timelog#load_timelog doesn't load activities if there's only an entry to
  # signal the start time for a day.
  def test_load_stream_with_starting_activity
    @stream.write("2012-01-31 10:52: Arrived\n")
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
  # activity stream, along with the current date and time.  The first activity
  # in a day is used to establish the start time, so nothing is added to the
  # list of activities.
  def test_record_activity
    @timelog.record_activity('Arrived')
    @stream.rewind
    assert_equal([], @timelog.activities)
    assert_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}: Arrived\n/,
                 @stream.read)
  end

  # Timelog::Timelog#record_activity formats the activity timestamp in
  # YYYY-MM-DD HH:MM format.  An explicit timestamp can optionally be
  # provided.
  def test_record_activity_formats_date
    timestamp1 = Time.new(2012, 1, 31, 8, 34)
    @timelog.record_activity('Arrived', timestamp1)
    timestamp2 = Time.new(2012, 1, 31, 10, 59)
    @timelog.record_activity('Reading mail', timestamp2)
    @stream.rewind
    assert_equal([{:start_time => timestamp1, :end_time => timestamp2,
                    :description => 'Reading mail'}],
                 @timelog.activities)
    assert_equal("2012-01-31 08:34: Arrived\n" <<
                 "2012-01-31 10:59: Reading mail\n",
                 @stream.read)
  end

  # Timelog::Timelog#record_activity writes a blank line to separate
  # activities that occur on different days.  A new days starts at 4am.
  def test_record_activity_detects_day_boundaries
    yesterday1 = Time.new(2012, 1, 31, 3, 47) # Yesterday at 3:47am
    @timelog.record_activity('Arrived', yesterday1)
    yesterday2 = Time.new(2012, 1, 31, 3, 59) # Yesterday at 3:59am
    @timelog.record_activity('Writing a test', yesterday2)
    today = Time.new(2012, 1, 31, 4) # Today at 4:00am
    @timelog.record_activity('Arrived', today)
    @stream.rewind
    assert_equal([{:start_time => Time.new(2012, 1, 31, 3, 47),
                    :end_time => Time.new(2012, 1, 31, 3, 59),
                    :description => 'Writing a test'}],
                 @timelog.activities)
    assert_equal("2012-01-31 03:47: Arrived\n" <<
                 "2012-01-31 03:59: Writing a test\n" <<
                 "\n" <<
                 "2012-01-31 04:00: Arrived\n",
                 @stream.read)
 end

  # Timelog::Timelog#record_activity correctly detects day changes when the
  # previous time is after 4am on the previous day.
  def test_record_activity_detects_day_boundaries_across_midnight
    yesterday1 = Time.new(2012, 1, 30, 20, 47) # Yesterday at 8:47pm
    @timelog.record_activity('Arrived', yesterday1)
    yesterday2 = Time.new(2012, 1, 30, 20, 59) # Yesterday at 8:59pm
    @timelog.record_activity('Writing a test', yesterday2)
    today = Time.new(2012, 1, 31, 4) # Today at 4:00am
    @timelog.record_activity('Arrived', today)
    @stream.rewind
    assert_equal([{:start_time => Time.new(2012, 1, 30, 20, 47),
                    :end_time => Time.new(2012, 1, 30, 20, 59),
                    :description => 'Writing a test'}],
                 @timelog.activities)
    assert_equal("2012-01-30 20:47: Arrived\n" <<
                 "2012-01-30 20:59: Writing a test\n" <<
                 "\n" <<
                 "2012-01-31 04:00: Arrived\n",
                 @stream.read)
 end

  # Timelog::Timelog#record_activity writes a blank line to separate
  # activities that occur on different days.  Day change detection works
  # correctly when more than 24 hours has passed since the last activity.
  def test_record_activity_detects_multiple_day_boundaries
    yesterday1 = Time.new(2012, 1, 29, 11) # Two days ago at 11:00am
    @timelog.record_activity('Arrived', yesterday1)
    yesterday2 = Time.new(2012, 1, 29, 12) # Two days ago at 12:00pm
    @timelog.record_activity('Reading mail', yesterday2)
    today1 = Time.new(2012, 1, 31, 15) # Today at 3:00pm
    @timelog.record_activity('Arrived', today1)
    today2 = Time.new(2012, 1, 31, 16) # Today at 4:00pm
    @timelog.record_activity('Reading mail', today2)
    @stream.rewind
    assert_equal("2012-01-29 11:00: Arrived\n" <<
                 "2012-01-29 12:00: Reading mail\n" <<
                 "\n" <<
                 "2012-01-31 15:00: Arrived\n" <<
                 "2012-01-31 16:00: Reading mail\n",
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
