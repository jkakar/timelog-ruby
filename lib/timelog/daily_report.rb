require 'time'

module Timelog
  # Daily report.
  module DailyReport
    # The number of work hours in a day.
    DAILY_WORK_HOURS = 8 * 60 * 60

    # Generate a report based on today's activities and write it to the output
    # stream.
    #
    # @param timelog [Timelog] The timelog containing the activities to report
    #   on.
    # @param output [IO] The output stream to write the report to.
    # @param today [Time] Optionally, the day to report on.  Defaults to
    #   today.
    def self.render(timelog, output, today=nil)
      today ||= Time.now
      activities = collect_activities(timelog, today)
      activities.each do |activity|
        duration = format_duration(activity[:duration])
        description = activity[:description]
        output.puts("#{duration}   #{description}")
      end
      time_working = 0
      time_slacking = 0
      time_left = DAILY_WORK_HOURS
      unless activities.empty?
        time_working = activities.map do |activity|
          activity[:duration] unless activity[:description].end_with?('**')
        end
        time_working = time_working.compact.reduce(:+)

        time_slacking = activities.map do |activity|
          activity[:duration] if activity[:description].end_with?('**')
        end
        time_slacking = time_slacking.compact.reduce(:+) || 0

        time_left = [0, (8 * 60 * 60) - time_working].max
        output.puts("\n")
      end
      output.puts("Time spent working:   #{format_duration(time_working)}")
      output.puts("Time spent slacking:  #{format_duration(time_slacking)}")
      output.puts("Time left at work:    #{format_duration(time_left)}")
    end

    private

    # Get the activities for the day.
    #
    # @param timelog [Timelog] The timelog containing the activities to report
    #   on.
    # @param today [Time] The day to report on.
    # @return [Array] A list of hashes with `:duration` and `:description`
    #   key/value pairs that represent activities for the specified day.
    def self.collect_activities(timelog, today)
      # Find activities matching the specified day.
      result = timelog.activities.collect do |activity|
        if (activity[:start_time].year == today.year &&
            activity[:start_time].month == today.month &&
            activity[:start_time].day == today.day)
          {duration: activity[:end_time] - activity[:start_time],
           description: activity[:description]}
        end
      end

      # Eliminate duplicates.
      activities = {}
      result.compact.each do |activity|
        duration = activity[:duration]
        description = activity[:description]
        if activities.has_key?(description)
          activities[description] += duration
        else
          activities[description] = duration
        end
      end

      # Return a list of unique activities for the day.
      result = []
      activities.each do |description, duration|
        result << {duration: duration, description: description}
      end
      result.sort_by { |activity| activity[:description] }
    end

    # Convert seconds to a '1 h 23 min' text format.
    #
    # @param seconds [Fixnum] The number of seconds to convert to a
    #   human-readable format.
    # @return [String] The formatted time.
    def self.format_duration(seconds)
      hours = 0
      minutes = seconds / 60
      if minutes > 59
        hours = minutes / 60
        minutes = minutes % 60
      end
      "%d h %02d min" % [hours, minutes]
    end
  end
end
