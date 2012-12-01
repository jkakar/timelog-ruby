require 'time'

module Timelog
  # A timelog keeps tracks of activities that occur over time.  Existing
  # activities are loaded from the stream and new ones are appended to it.
  class Timelog
    # A new day starts at 4:00am in the morning.
    DAY_BOUNDARY_HOUR = 4

    attr_reader :activities

    def initialize(activities, stream)
      @activities = activities
      @stream = stream
      @next_start_time = nil
    end

    # Write an activity to the timelog stream.
    def record_activity(description, end_time=nil)
      end_time ||= Time.now
      start_time = get_start_time(end_time)
      if start_time.nil?
        @next_start_time = end_time
        write_separator unless @activities.empty?
      else
        @activities << {:start_time => start_time, :end_time => end_time,
                        :description => description}
      end
      write_activity(end_time, description)
    end

    private

    # Get the start time from the last activity or nil if one isn't available
    # or if the end time is the first of the day.  If this is the first
    # activity, after starting the day, the @next_start_time queued from the
    # starting activity is used.
    def get_start_time(end_time)
      start_time = @next_start_time
      if start_time.nil?
        start_time = @activities[-1][:end_time] unless @activities.empty?
      end

      if start_time && (more_than_a_day_passed?(start_time, end_time) ||
                        crossed_day_change_boundary?(start_time, end_time))
        start_time = nil
      end

      # Reset the next start time since, if it existed, it's now been used.
      @next_start_time = nil
      start_time
    end

    # True if a more than a day has passed between the current time and
    # previous time.
    def more_than_a_day_passed?(start_time, end_time)
      end_time - start_time > 60 * 60 * 24
    end

    # True if the current time has crossed the day boundary since the previous
    # time.
    def crossed_day_change_boundary?(start_time, end_time)
      start_time.day != end_time.day ||
        (start_time.hour < 4 && end_time.hour >= 4)
    end

    # Write an activity to the stream.
    def write_activity(end_time, description)
      @stream.puts("#{end_time.strftime '%Y-%m-%d %H:%M'}: #{description}")
    end

    # Write a day separator to the stream.
    def write_separator
      @stream.puts('')
    end
  end

  # Load a timelog from a file stream.
  def self.load_stream(stream)
    activities = []
    start_time = nil
    stream.each do |line|
      result = line.scan(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}): (.*)\n/)
      if result.empty?
        start_time = nil
      else
        item = result[0]
        end_time = Time.new(item[0].to_i, item[1].to_i, item[2].to_i,
                            item[3].to_i, item[4].to_i)
        description = item[5]
        if start_time.nil?
          start_time = end_time
        else
          activities << {:start_time => start_time, :end_time => end_time,
                         :description => description}
          start_time = end_time
        end
      end
    end
    Timelog.new(activities, stream)
  end

  private

  # Get an object with activity information extract from the line or nil if
  # the line is not in the expected format.
  def self.parse_activity_line(line)
    result = line.scan(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}): (.*)\n/)
    unless result.empty?
      item = result[0]
      timestamp = Time.new(item[0].to_i, item[1].to_i, item[2].to_i,
                           item[3].to_i, item[4].to_i)
      {timestamp: timestamp, description: item[5]}
    end
  end
end
