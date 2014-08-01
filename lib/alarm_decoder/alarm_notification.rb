require_relative '../alarm_decoder'
require 'prowl'
require 'mail'

module AlarmDecoder
  class AlarmNotification
    def initialize(status)
      @status = status
      @redis  = Redis.new
    end

    attr_reader :status, :redis

    def run
      if alarm?
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
          :event => type,
          :description => zone,
          :priority => 2
        )
      rescue StandardError => e
        puts "Error sending prowl message: #{e.message}"
      end

      begin
        Mail.deliver do
          from     ENV['SMTP_USERNAME']
          to       ENV['NOTIFY_EMAILS'].split(',')
          subject  '146 Union Street - Home Security'
          body     "#{type} in #{zone}"
        end
      rescue StandardError => e
        puts "Error sending email: #{e.message}"
      end

      self.notified = true
    end

    def notified=(notified)
      redis.set("alarm-notified", notified)
    end

    def notification_sent?
      redis.get("alarm-notified") == "true"
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
  end
end
