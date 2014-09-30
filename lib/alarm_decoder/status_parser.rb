require 'yaml'

module AlarmDecoder
  class StatusParser
    def initialize(raw_status)
      @raw_status = raw_status
    end

    attr_reader :raw_status

    def status
      return unless parsable?

      {
        ready:           bit_state(0),
        armed_away:      bit_state(1),
        armed_home:      bit_state(2),
        alarm_occured:   bit_state(9),
        alarm_sounding:  bit_state(10),
        armed_instant:   bit_state(12),
        fire:            bit_state(13),
        zone_issue:      bit_state(14),
        perimeter_only:  bit_state(15),
        zone_number:     zone_number,
        zone_name:       zone_name,
        display_message: display_message
      }
    end

    def parsable?
      !!raw_status[/\[/]
    end

    private

    def zone_number
      @zone_name ||= split_status[1].to_i
    end

    def zone_name
      @zone_name = config.fetch("zones", {})[zone_number]
    end

    def display_message
      @display_message ||= split_status.last
    end

    def split_status
      @split_status ||= raw_status.split(',')
    end

    def bit_field
      @bit_field ||= split_status.first.gsub(/\[|\]/, '').chars.map(&:to_i)
    end

    def bit_state(index)
      bit_field[index] == 1
    end

    def config
      @config ||= begin
        config_file = ENV['ALARM_DECODER_CONFIG']
        config_file ? YAML.load_file(config_file) : {}
      end
    end
  end
end
