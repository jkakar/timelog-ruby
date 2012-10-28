require 'optparse'

require 'timelog/activities'


module Timelog
  # Raised if usage text should be displayed.
  class UsageError < StandardError
    def initialize(option_parser)
      @option_parser = option_parser
    end

    def to_s
      @option_parser.to_s
    end
  end

  # Command-line client parses and validates arguments and writes activity
  # data to the stream.
  class CLI
    def initialize(stream)
      @stream = stream
    end

    # Parse command-line arguments and perform the requested operation.
    def run(*args)
      options, args = parse_command_line_options!(args)
      if args.empty?
        raise ArgumentError.new('You must specify an activity description.')
      else
        Activities.new(@stream).record_activity(args[0])
      end
    end

    private

    # Parse command-line arguments and return an options object and a list of
    # remaining arguments.
    def parse_command_line_options!(args)
      options = {}
      OptionParser.new do |opts|
        # TODO: Put command-line options here

        # This displays the help screen, all programs are
        # assumed to have this option.
        opts.on('-h', '--help', 'Display this screen') do
          raise UsageError.new(opts)
        end
      end.parse!(args)
      return options, args
    end
  end
end
