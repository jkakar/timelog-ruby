module Timelog
  class Timelog

    def initialize(stream)
      @stream = stream
    end

    def record_activity(description)
      @stream.puts("#{DateTime.now.strftime '%Y-%m-%d %H:%M'}: #{description}")
    end

  end
end
