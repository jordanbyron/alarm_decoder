require_relative '../alarm_decoder'
require 'prowl'

module AlarmDecoder
  class ZoneFaultNotification
    def initialize(status)
      @status = status
      @redis  = Redis.new
    end

    attr_reader :status

    def run
      if zone_faulted?
        notify unless notification_sent?
      else
        self.notified = false
      end
    end

    private

    def notify
      begin
        Prowl.add(
          :apikey => ENV['PROWL_API_KEY'],
          :application => "House Security",
          :event => "Zone Fault",
          :description => zone,
          :priority => 0
        )
      rescue StandardError => e
        puts "Error sending prowl message: #{e.message}"
      end

      self.notified = true
    end

    def notify=(notified)
      redis.set("zone-fault-notified", notified)
    end

    def notification_sent?
      redis.get("zone-fault-notified") == "true"
    end

    def zone_faulted?
      !status["ready"]
    end

    def zone
      @zone ||= status["zone_name"]
    end
  end
end
