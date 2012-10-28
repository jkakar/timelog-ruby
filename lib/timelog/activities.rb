require 'date'


module Timelog
  # A timelog keeps tracks of activities that occur over time.  Existing
  # activities are loaded from the stream and new ones are appended to it.
  class Activities
    # A new day starts at 4:00am in the morning.
    DAY_BOUNDARY_HOUR = 4

    attr_reader :activities

    def initialize(stream)
      @activities = []
      @stream = stream
      @stream.each do |line|
        activity = parse_activity_line(line)
        @activities << activity unless activity.nil?
      end
    end

    # Write an activity to the timelog stream.
    def record_activity(description, timestamp=nil)
      timestamp ||= DateTime.now

      previous_activity = @activities[-1]
      unless previous_activity.nil?
        if (timestamp - previous_activity[:timestamp] > 1 ||
            (previous_activity[:timestamp].hour < DAY_BOUNDARY_HOUR &&
             timestamp.hour >= DAY_BOUNDARY_HOUR))
          @stream.puts('')
        end
      end

      @stream.puts("#{timestamp.strftime '%Y-%m-%d %H:%M'}: #{description}")
      @activities << {timestamp: timestamp, description: description}
    end

    private

    # Get an object with activity information extract from the line or nil if
    # the line is not in the expected format.
    def parse_activity_line(line)
      result = line.scan(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}): (.*)\n/)
      unless result.empty?
        item = result[0]
        timestamp = DateTime.new(item[0].to_i, item[1].to_i, item[2].to_i,
                                 item[3].to_i, item[4].to_i)
        {timestamp: timestamp, description: item[5]}
      end
    end
  end
end
