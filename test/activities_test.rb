require 'date'
require 'minitest/autorun'
require 'minitest/pride'
require 'stringio'

require 'timelog/activities'


class ActivitiesTest < MiniTest::Unit::TestCase
  def setup
    @stream = StringIO.new
    @activities = Timelog::Activities.new(@stream)
  end

  # Activities#initialize loads activities from the stream.  This is
  # essentially a no-op if the stream is empty.
  def test_initialize_with_empty_stream
    assert_equal([], @activities.activities)
  end

  # Activities#initialize loads activities from the stream.
  def test_initialize_loads_activities_from_stream
    stream = StringIO.new("2012-01-31 10:59: Writing a test\n")
    activities = Timelog::Activities.new(stream)
    timestamp = DateTime.new(2012, 1, 31, 10, 59)
    assert_equal([{timestamp: timestamp, description: 'Writing a test'}],
                 activities.activities)
  end

  # Activities#initialize ignores empty lines when reading from the stream.
  def test_initialize_ignores_empty_lines
    stream = StringIO.new("\n\n\n")
    activities = Timelog::Activities.new(stream)
    assert_equal([], activities.activities)
  end

  # Activities#initialize ignores malformed lines when reading from the
  # stream.
  def test_initialize_ignores_malformed_lines
    stream = StringIO.new("This isn't a valid activity line\n")
    activities = Timelog::Activities.new(stream)
    assert_equal([], activities.activities)
  end

  # Activities#record_activity writes the specified description to the
  # activity stream, along with the current date and time.
  def test_record_activity
    @activities.record_activity('Writing a test')
    assert_match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}: Writing a test\n/,
                 @stream.string)
  end

  # Activities#record_activity formats the activity timestamp in YYYY-MM-DD
  # HH:MM format.  An explicit DateTime timestamp can optionally be provided.
  def test_record_activity_formats_date
    timestamp = DateTime.new(2012, 1, 31, 10, 59)
    @activities.record_activity('Writing a test', timestamp)
    assert_equal("2012-01-31 10:59: Writing a test\n", @stream.string)
  end

  # Activities#record_activity writes a blank line to separate activities that
  # occur on different days.  The default day boundary is at 4am.
  def test_record_activity_detects_day_boundaries
    yesterday = DateTime.new(2012, 1, 31, 3, 59) # Yesterday at 3:59am
    @activities.record_activity('Writing a test', yesterday)
    today = DateTime.new(2012, 1, 31, 4) # Today at 4:00am
    @activities.record_activity('Writing another test', today)
    assert_equal("2012-01-31 03:59: Writing a test\n" <<
                 "\n" <<
                 "2012-01-31 04:00: Writing another test\n",
                 @stream.string)
  end

  # Activities#record_activity writes a blank line to separate activities that
  # occur on different days.  Day change detection works correctly when the
  # last activity was more than one day before the current one.
  def test_record_activity_detects_multiple_day_boundaries
    yesterday = DateTime.new(2012, 1, 29, 12) # Two days ago at 12:00pm
    @activities.record_activity('Writing a test', yesterday)
    today = DateTime.new(2012, 1, 31, 15) # Today at 3:00pm
    @activities.record_activity('Writing another test', today)
    assert_equal("2012-01-29 12:00: Writing a test\n" <<
                 "\n" <<
                 "2012-01-31 15:00: Writing another test\n",
                 @stream.string)
  end

  # Activities#record_activity groups activities that occur on the same day
  # together in the activity file, one per line.
  def test_record_activity_groups_activities_on_the_same_day
    today1 = DateTime.new(2012, 1, 31, 15) # Today at 3:00pm
    @activities.record_activity('Writing a test', today1)
    today2 = DateTime.new(2012, 1, 31, 15, 5) # Today at 3:05pm
    @activities.record_activity('Writing another test', today2)
    assert_equal("2012-01-31 15:00: Writing a test\n" <<
                 "2012-01-31 15:05: Writing another test\n",
                 @stream.string)
  end
end
