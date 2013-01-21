require 'minitest/unit'
require 'stringio'
require 'time'

require 'timelog'

class WeeklyReportTest < MiniTest::Unit::TestCase
  def setup
    @stream = Tempfile.new('timelog')
    @timelog = Timelog::Timelog.new([], @stream)
    @output = StringIO.new
  end

  def teardown
    @stream.close
    @stream.unlink
  end

  # Timelog::WeeklyReport.render writes a basic report to the output stream,
  # without any activity information, when the timelog is empty.
  def test_render_without_activities
    Timelog::WeeklyReport.render(@timelog, @output)
    assert_equal("Time spent working:   0 h 00 min\n" <<
                 "Time spent slacking:  0 h 00 min\n",
                 @output.string)
  end

  # Timelog::WeeklyReport.render writes a simple report of activities from the
  # specified week, sorted alphabetically, to the output stream.  The week
  # starts on Monday.
  def test_render
    sunday1 = Time.new(2013, 1, 6, 14, 15) # Sunday at 1:19pm
    @timelog.record_activity('Arrived', sunday1)
    sunday2 = Time.new(2013, 1, 6, 14, 15) # Sunday at 2:15pm
    @timelog.record_activity('Writing code', sunday2)
    monday1 = Time.new(2013, 1, 7, 15) # Monday at 3:00pm
    @timelog.record_activity('Arrived', monday1)
    monday2 = Time.new(2013, 1, 7, 15, 5) # Monday at 3:05pm
    @timelog.record_activity('Writing a test', monday2)
    monday3 = Time.new(2013, 1, 7, 15, 12) # Monday at 3:12pm
    @timelog.record_activity('Reading mail', monday3)
    tuesday1 = Time.new(2013, 1, 8, 15) # Tuesday at 3:00pm
    @timelog.record_activity('Arrived', tuesday1)
    tuesday2 = Time.new(2013, 1, 8, 15, 5) # Tuesday at 3:05pm
    @timelog.record_activity('Writing a test', tuesday2)
    next_monday1 = Time.new(2013, 1, 14, 15) # Next Monday at 3:00pm
    @timelog.record_activity('Arrived', next_monday1)
    next_monday2 = Time.new(2013, 1, 14, 15, 5) # Next Monday at 3:05pm
    @timelog.record_activity('Writing a test', next_monday2)

    # The report only includes activities from the current week, ie, those
    # that occurred on Monday and Tuesday.  The activities from Sunday and
    # next Monday are not included in the report.
    thursday = Time.new(2013, 1, 10)
    Timelog::WeeklyReport.render(@timelog, @output, thursday)
    assert_equal("0 h 07 min   Reading mail\n" <<
                 "0 h 05 min   Writing a test\n" <<
                 "\n" <<
                 "Time spent working:   0 h 12 min\n" <<
                 "Time spent slacking:  0 h 00 min\n",
                 @output.string)
  end
end
