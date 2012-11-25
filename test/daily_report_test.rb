require 'minitest/unit'
require 'stringio'
require 'time'

require 'timelog/daily_report'
require 'timelog/timelog'


class DailyReportTest < MiniTest::Unit::TestCase
  def setup
    @stream = Tempfile.new('timelog')
    @timelog = Timelog::Timelog.new([], @stream)
    @output = StringIO.new
  end

  def teardown
    @stream.close
    @stream.unlink
  end

  # Timelog::DailyReport.render writes a basic report to the output stream,
  # without any activity information, when the timelog is empty.
  def test_render_without_activities
    Timelog::DailyReport.render(@timelog, @output)
    assert_equal("Total work done:    0 h 00 min\n" <<
                 "Time left at work:  8 h 00 min\n",
                 @output.string)
  end

  # Timelog::DailyReport.render writes a basic report, containing activities
  # from the specified day, to the output stream.
  def test_render
    yesterday1 = Time.new(2012, 1, 30, 14, 15) # Yesterday at 1:19pm
    @timelog.record_activity('Arrived', yesterday1)
    yesterday2 = Time.new(2012, 1, 30, 14, 15) # Yesterday at 2:15pm
    @timelog.record_activity('Writing code', yesterday2)
    today1 = Time.new(2012, 1, 31, 15) # Today at 3:00pm
    @timelog.record_activity('Arrived', today1)
    today2 = Time.new(2012, 1, 31, 15, 5) # Today at 3:05pm
    @timelog.record_activity('Writing a test', today2)
    today3 = Time.new(2012, 1, 31, 15, 12) # Today at 3:12pm
    @timelog.record_activity('Writing another test', today3)
    Timelog::DailyReport.render(@timelog, @output, Time.new(2012, 1, 31))
    assert_equal("0 h 05 min   Writing a test\n" <<
                 "0 h 07 min   Writing another test\n" <<
                 "\n" <<
                 "Total work done:    0 h 12 min\n" <<
                 "Time left at work:  7 h 48 min\n",
                 @output.string)
  end

  # Timelog::DailyReport.render groups activities with the same description.
  def test_render_groups_activities
    today1 = Time.new(2012, 1, 31, 15) # Today at 3:00pm
    @timelog.record_activity('Arrived', today1)
    today2 = Time.new(2012, 1, 31, 15, 5) # Today at 3:05pm
    @timelog.record_activity('Writing a test', today2)
    today3 = Time.new(2012, 1, 31, 15, 12) # Today at 3:12pm
    @timelog.record_activity('Reading mail', today3)
    today4 = Time.new(2012, 1, 31, 15, 17) # Today at 3:17pm
    @timelog.record_activity('Reading mail', today4)
    Timelog::DailyReport.render(@timelog, @output, Time.new(2012, 1, 31))
    assert_equal("0 h 12 min   Reading mail\n" <<
                 "0 h 05 min   Writing a test\n" <<
                 "\n" <<
                 "Total work done:    0 h 17 min\n" <<
                 "Time left at work:  7 h 43 min\n",
                 @output.string)
  end

  # Timelog::DailyReport.render sets the time left at work to zero when more
  # than 8 hours have been spent at work.
  def test_render_calculates_time_left
    today1 = Time.new(2012, 1, 31, 9) # Today at 9:00am
    @timelog.record_activity('Arrived', today1)
    today2 = Time.new(2012, 1, 31, 17, 1) # Today at 5:01pm
    @timelog.record_activity('Long walk by the beach', today2)
    Timelog::DailyReport.render(@timelog, @output, Time.new(2012, 1, 31))
    assert_equal("8 h 01 min   Long walk by the beach\n" <<
                 "\n" <<
                 "Total work done:    8 h 01 min\n" <<
                 "Time left at work:  0 h 00 min\n",
                 @output.string)
  end

  # Timelog::DailyReport.render doesn't count slacking activities, those that
  # end with '**', when determing how much time has been spent working.
  def test_render_calculates_time_spent
    today1 = Time.new(2012, 1, 31, 15) # Today at 3:00pm
    @timelog.record_activity('Arrived', today1)
    today2 = Time.new(2012, 1, 31, 15, 5) # Today at 3:05pm
    @timelog.record_activity('Writing a test', today2)
    today3 = Time.new(2012, 1, 31, 16, 12) # Today at 4:12pm
    @timelog.record_activity('Lunch **', today3)
    Timelog::DailyReport.render(@timelog, @output, Time.new(2012, 1, 31))
    assert_equal("1 h 07 min   Lunch **\n" <<
                 "0 h 05 min   Writing a test\n" <<
                 "\n" <<
                 "Total work done:    0 h 05 min\n" <<
                 "Time left at work:  7 h 55 min\n",
                 @output.string)
  end
end
