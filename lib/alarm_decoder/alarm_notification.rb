require_relative '../alarm_decoder'
require 'prowl'
require 'mail'

module AlarmDecoder
  class AlarmNotification
    def initialize(config)
      @config = config
      @redis  = Redis.new
    end

    attr_reader :status, :redis, :config

    def run(status)
      @status = status

      if alarm?
        notify
      else
        redis.del "alarm-notified-prowl"
        redis.del "alarm-notified-email"
        redis.del "alarm-at"
      end
    end

    private

    def notify
      redis.set("alarm-at", Time.now.to_i) if alarm_duration == 0

      (config['prowl'] || []).each do |key, delay_seconds|
        next if notification_sent?(:prowl, key) || delay?(delay_seconds)

        Prowl.add(
          apikey:      key,
          application: "House Security",
          event:       type,
          description: zone,
          priority:    2
        )

        notified :prowl, key
      end

      (config['emails'] || []).each do |email, delay_seconds|
        next if notification_sent?(:email, email) || delay?(delay_seconds)

        from = config['from_address']
        body = "#{type} in #{zone}"

        Mail.deliver do
          from     from
          to       email
          subject  '146 Union Street - Home Security'
          body     body
        end

        notified :email, email
      end
    end

    def notified(type, key)
      redis.rpush("alarm-notified-#{type}", key)
    end

    def notification_sent?(type, key)
      redis.lrange("alarm-notified-#{type}", 0, -1).include?(key.to_s)
    end

    def alarm?
      status["alarm_sounding"] || status["fire"]
    end

    def type
      @type ||= status["fire"] ? "Fire" : "Alarm"
    end

    def zone
      @zone ||= status["zone_name"]
    end

    def alarm_duration
      alarm_at = redis.get("alarm-at")

      alarm_at ? Time.now - Time.at(alarm_at.to_i) : 0
    end

    def delay?(delay_seconds)
      return false if status["panic"] # Notify everyone in a panic situation
      delay_seconds && alarm_duration < delay_seconds
    end
  end
end
