module Timelog
  # Command-line client parses and validates arguments and writes activity
  # data to the stream.
  class CLI
    def initialize(stream)
      @stream = stream
    end

    # Parse command-line arguments and perform the requested operation.
    def start(*args)
      if args.empty?
        raise ArgumentError.new('You must specify an activity description.')
      end
      Timelog.new(@stream).record_activity(args[0])
    end
  end
end
