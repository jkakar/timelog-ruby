require 'date'
require 'pp'


module Timelog
  module DailyReport
    # Generate a report based on today's activities and write it to the output
    # stream.
    def self.render(activities, output, today=nil)
      today ||= DateTime.now
      all_activities = collect_activities(activities, today)
      pp all_activities
      # all_activities.each do |activity|
      #   output.puts('')
      # end
      output.puts('Total work done:    0 h 00 min')
      output.puts('Time left at work:  8 h 00 min')
    end

    private

    def self.collect_activities(activities, today)
      activities.activities.select do |activity|
        activity if (activity[:timestamp].year == today.year &&
                     activity[:timestamp].month == today.month &&
                     activity[:timestamp].day == today.day)
      end
    end
  end
end
