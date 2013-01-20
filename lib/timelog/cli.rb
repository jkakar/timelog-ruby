require 'optparse'

module Timelog
  # Raised if usage text should be displayed.
  class UsageError < StandardError
    # Instantiate a usage error exception.
    def initialize(option_parser)
      @option_parser = option_parser
    end

    # Convert the usage error to a string that contains help information about
    # command-line arguments and options.
    #
    # @return [String] The usage text to display when help is requested.
    def to_s
      @option_parser.to_s
    end
  end

  # Command-line client parses and validates arguments and writes activity
  # data to the activity stream.  Reporting and other information for the user
  # is written to the output stream.
  class CLI
    # Instantiate a command-line runner.
    #
    # @param stream [IO] The stream to load activities from, typically the
    #   file stored at `~/.timelog.txt`.
    # @param output [IO] The stream to write output to, typically `$stdout`.
    def initialize(stream, output)
      @stream = stream
      @output = output
    end

    # Parse command-line arguments and perform the requested operation.
    #
    # @param args [Array] The list of command-line arguments provided when the
    #   `timelog` program was run.
    def run(*args)
      options, args = parse_command_line_options!(args)
      timelog = ::Timelog::load_stream(@stream)
      unless args.empty? || args[0].strip.empty?
        timelog.record_activity(args[0])
      end
      DailyReport::render(timelog, @output)
    end

    private

    # Parse command-line arguments and return an options object and a list of
    # remaining arguments.
    #
    # @param args [Array] The list of command-line arguments provided when the
    #   `timelog` program was run.
    # @return [Array] An `[options, arguments]` 2-tuple parsed from the
    #   provided command-line arguments.
    def parse_command_line_options!(args)
      options = {}
      OptionParser.new do |parser|
        parser.on('-h', '--help', 'Display this screen') do
          raise UsageError.new(parser)
        end
        parser.on('-w', '--weekly', 'Display weekly report') do
          options['report'] = 'weekly'
        end
      end.parse!(args)
      return options, args
    end
  end
end
