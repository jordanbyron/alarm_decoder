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
        ready:           ready,
        armed_away:      armed_away,
        armed_home:      armed_home,
        alarm_occurred:  bit_state(9),
        alarm_sounding:  alarm_sounding,
        armed_instant:   armed_instant,
        fire:            fire,
        zone_issue:      bit_state(14),
        perimeter_only:  bit_state(15),
        zone_number:     zone_number,
        zone_name:       zone_name,
        display_message: display_message,
        panic:           panic,
        human_status:    human_status
      }
    end

    def parsable?
      !!raw_status[/\[/]
    end

    private

    def ready
      bit_state(0)
    end

    def armed_away
      bit_state(1)
    end

    def armed_home
      bit_state(2)
    end

    def armed_instant
      bit_state(12)
    end

    def fire
      bit_state(13)
    end

    def zone_number
      @zone_name ||= split_status[1].to_i
    end

    def zone_name
      @zone_name = AlarmDecoder.config.fetch("zones", {})[zone_number]
    end

    def panic
      alarm_sounding && zone_number == 99
    end

    def alarm_sounding
      bit_state(10)
    end

    def display_message
      @display_message ||= split_status.last
    end

    def human_status
      zone = zone_name || "Zone #{zone_number}"

      if panic
        "PANIC"
      elsif alarm_sounding
        "ALARM: #{zone}"
      elsif fire
        "FIRE"
      elsif armed_home || armed_away
        type = armed_home ? "stay" : "away"
        "Armed #{type}"
      elsif ready
        "Ready"
      else
        zone
      end
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
  end
end
