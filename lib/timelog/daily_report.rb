require 'time'


module Timelog
  module DailyReport
    # Generate a report based on today's activities and write it to the output
    # stream.
    def self.render(timelog, output, today=nil)
      today ||= Time.now
      activities = collect_activities(timelog, today)
      activities.each do |activity|
        duration = format_duration(activity[:duration])
        description = activity[:description]
        output.puts("#{duration}   #{description}")
      end
      time_spent = 0
      time_left = (8 * 60 * 60)
      unless activities.empty?
        time_spent = activities.map do |a|
          a[:duration] unless a[:description].end_with?('**')
        end
        time_spent = time_spent.compact.reduce(:+)
        time_left = (8 * 60 * 60) - time_spent
        time_left = 0 if time_left < 0
        output.puts("\n")
      end
      output.puts("Total work done:    #{format_duration(time_spent)}")
      output.puts("Time left at work:  #{format_duration(time_left)}")
    end

    private

    # Get the activities for the day.
    def self.collect_activities(timelog, today)
      # Find activities matching the specified day.
      result = timelog.activities.collect do |activity|
        if (activity[:start_time].year == today.year &&
            activity[:start_time].month == today.month &&
            activity[:start_time].day == today.day)
          {:duration => activity[:end_time] - activity[:start_time],
            :description => activity[:description]}
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
        result << {:duration => duration, :description => description}
      end
      result.sort_by { |activity| activity[:description] }
    end

    def self.format_duration(seconds)
      hours = 0
      minutes = seconds / 60
      if minutes > 60
        hours = minutes / 60
        minutes = minutes % 60
      end
      "%d h %02d min" % [hours, minutes]
    end
  end
end
