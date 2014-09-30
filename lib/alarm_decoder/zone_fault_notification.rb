require_relative '../alarm_decoder'
require 'prowl'

module AlarmDecoder
  class ZoneFaultNotification
    def initialize(config)
      @config = config
      @redis  = Redis.new
    end

    attr_reader :status, :redis, :config

    def run(status)
      @status = status

      if notifications_enabled? && zone_faulted?
        notify unless notification_sent?
      else
        self.notified = false
      end
    end

    private

    def notify
      config['prowl_keys'].each do |key|
        Prowl.add(
          apikey:      key,
          application: "House Security",
          event:       "Zone Fault",
          description: zone,
          priority:    0
        )
      end

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
      config["enabled"] == true
    end

    def zone_faulted?
      !status["ready"] &&
      !%w[armed_away armed_home alarm_sounding fire].any? {|v| status[v] }
    end

    def zone
      @zone ||= status["zone_name"]
    end
  end
end
