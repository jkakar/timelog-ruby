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
        time_spent = activities.map { |a| a[:duration] }.reduce(:+)
        time_left = (8 * 60 * 60) - time_spent
        output.puts("\n")
      end
      output.puts("Total work done:    #{format_duration(time_spent)}")
      output.puts("Time left at work:  #{format_duration(time_left)}")
    end

    private

    # Get the activities for the day.
    def self.collect_activities(timelog, today)
      activities = timelog.activities.collect do |activity|
        if (activity[:start_time].year == today.year &&
            activity[:start_time].month == today.month &&
            activity[:start_time].day == today.day)
          {:duration => activity[:end_time] - activity[:start_time],
            :description => activity[:description]}
        end
      end
      activities.compact
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
