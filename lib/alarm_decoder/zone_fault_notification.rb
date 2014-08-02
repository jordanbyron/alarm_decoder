require_relative '../alarm_decoder'
require 'prowl'

module AlarmDecoder
  class ZoneFaultNotification
    def initialize(status)
      @status = status
      @redis  = Redis.new
    end

    attr_reader :status, :redis

    def run
      if notifications_enabled? && zone_faulted?
        notify unless notification_sent?
      else
        self.notified = false
      end
    end

    private

    def notify
      Prowl.add(
        :apikey => ENV['PROWL_API_KEY'],
        :application => "House Security",
        :event => "Zone Fault",
        :description => zone,
        :priority => 0
      )

    self.notified = true

    rescue StandardError => e
      puts "Error sending prowl message: #{e.message}"
    end

    def notified=(notified)
      redis.set("zone-fault-notified", notified)
    end

    def notification_sent?
      redis.get("zone-fault-notified") == "true"
    end

    def notifications_enabled?
      redis.get("zone-fault-notifications-enabled") == "true"
    end

    def zone_faulted?
      !status["ready"] &&
      !%w[armed_away armed_stay alarm_sounding fire].any? {|v| status[v] }
    end

    def zone
      @zone ||= status["zone_name"]
    end
  end
end
