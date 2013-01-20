require 'time'

module Timelog
  # A timelog keeps tracks of activities that occur over time.  Existing
  # activities are loaded from the stream and new ones are appended to it.
  class Timelog
    # A new day starts at 4:00am in the morning.
    DAY_BOUNDARY_HOUR = 4

    # An array of hashes containing `:start_time`, `:end_time` and
    # `:description` key/value pairs that represent activities in the timelog.
    attr_reader :activities

    # Instantiate a timelog.
    #
    # @param activities [Array] A list of activities in the timelog.
    # @param stream [IO] The stream to write activities to, typically the file
    #   stored at `~/.timelog.txt`.
    # @param next_start_time [Time] Optionally, the start time to use for the
    #   next provided activity.  This is used when the last activity
    #   represents the first activity of the day, which is the start time of
    #   the next activity.  Defaults to nil.
    def initialize(activities, stream, next_start_time=nil)
      @activities = activities
      @stream = stream
      @next_start_time = next_start_time
    end

    # Write an activity to the timelog stream.
    #
    # @param description [String] A description of the activity that was
    #   performed, such as *Reading mail*.
    # @param end_time [Time] Optionally, the time to set as the end of the
    #   activity being recorded.  Defaults to now.
    def record_activity(description, end_time=nil)
      end_time ||= Time.now
      start_time = get_start_time(end_time)
      if start_time.nil?
        @next_start_time = end_time
        write_separator unless @activities.empty?
      else
        @activities << {start_time: start_time,
                        end_time: end_time,
                        description: description}
      end
      write_activity(end_time, description)
    end

    private

    # Get the start time from the last activity or nil if one isn't available
    # or if the end time is the first of the day.  If this is the first
    # activity, after starting the day, the @next_start_time queued from the
    # starting activity is used.
    #
    # @param end_time [Time] The end time of the last recorded activity.
    # @return [Time] The start time to record for the new activity being
    #   reported.
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

    # Determine whether more than a day has passed between the start time of
    # the new activity and the end time of the previous activity.
    #
    # @param start_time [Time] The start time of the new activity being
    #   reported.
    # @param end_time [Time] The end time of the last activity that was
    #   reported.
    # @return [TrueClass,FalseClass] True if more than a day has passed since
    #   the last recorded activity, otherwise false.
    def more_than_a_day_passed?(start_time, end_time)
      end_time - start_time > 60 * 60 * 24
    end

    # Determine whether the day boundary has been cross between the start time
    # of the new activity and the end time of the previous activity.
    #
    # @param start_time [Time] The start time of the new activity being
    #   reported.
    # @param end_time [Time] The end time of the last activity that was
    #   reported.
    # @return [TrueClass,FalseClass] True if the start time of the current
    #   activity has crossed the day boundary since the last recorded
    #   activity, otherwise false.
    def crossed_day_change_boundary?(start_time, end_time)
      different_day = start_time.day != end_time.day
      crossed_day_boundary = start_time.hour < 4 && end_time.hour >= 4
      different_day || crossed_day_boundary
    end

    # Write an activity to the stream.
    #
    # @param end_time [Time] The end time of the activity being recorded.
    # @param description [String] The description of the activity being
    #   recorded.
    def write_activity(end_time, description)
      @stream.puts("#{end_time.strftime '%Y-%m-%d %H:%M'}: #{description}")
    end

    # Write a day separator to the stream.
    def write_separator
      @stream.puts('')
    end
  end

  # Load a timelog from a file stream.
  #
  # @param stream [IO] The input stream to load activities from.
  # @return [Timelog] The timelog instance containing the loaded activities.
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
          activities << {start_time: start_time,
                         end_time: end_time,
                         description: description}
          start_time = end_time
        end
      end
    end
    Timelog.new(activities, stream, start_time)
  end
end
