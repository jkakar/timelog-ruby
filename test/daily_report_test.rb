require 'date'
require 'minitest/autorun'
require 'minitest/pride'
require 'stringio'

require 'timelog/activities'
require 'timelog/daily_report'


class DailyReportTest < MiniTest::Unit::TestCase
  def setup
    @stream = StringIO.new
    @activities = Timelog::Activities.new(@stream)
    @output = StringIO.new
  end

  # DailyReport.render writes a basic report to the output stream, without any
  # activity information, when the timelog is empty.
  def test_render_without_activities
    Timelog::DailyReport.render(@activities, @output)
    assert_equal("Total work done:    0 h 00 min\n" <<
                 "Time left at work:  8 h 00 min\n",
                 @output.string)
  end

  # DailyReport.render writes a basic report, containing activities from the
  # specified day, to the output stream.
  def test_render
    yesterday = DateTime.new(2012, 1, 30, 14, 15) # Yesterday at 2:15pm
    @activities.record_activity('Writing code', yesterday)
    today1 = DateTime.new(2012, 1, 31, 15) # Today at 3:00pm
    @activities.record_activity('Arrived', today1)
    today2 = DateTime.new(2012, 1, 31, 15, 5) # Today at 3:05pm
    @activities.record_activity('Writing a test', today2)
    today3 = DateTime.new(2012, 1, 31, 15, 12) # Today at 3:12pm
    @activities.record_activity('Writing another test', today3)
    Timelog::DailyReport.render(@activities, @output,
                                DateTime.new(2012, 1, 31))
    assert_equal("0 h 05 min    Writing a test\n" <<
                 "0 h 07 min    Writing another test\n" <<
                 "\n" <<
                 "Total work done:    0 h 12 min\n" <<
                 "Time left at work:  7 h 48 min\n",
                 @output.string)
  end
end
