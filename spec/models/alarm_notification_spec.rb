require_relative '../spec_helper'
require_relative '../../lib/alarm_decoder/alarm_notification'

describe AlarmDecoder::AlarmNotification do
  let(:redis)        { Redis.new }
  let(:notification) { AlarmDecoder::AlarmNotification.new(@config) }

  describe "prowl" do
    before do
      @config = { "prowl" => ["1234", "4567"] }

      redis.del "alarm-notified-prowl"
    end

    it 'skips prowl notifications when keys missing' do
      @config = {}

      notification.run("alarm_sounding" => true)
    end

    it 'sends a notification when there is an alarm' do
      Prowl.stub_any_instance(:perform, 200) do
        notification.run("alarm_sounding" => true)
      end

      redis.lrange("alarm-notified-prowl", 0, -1).must_equal @config['prowl']
    end

    it 'only sends one notification per key per alarm' do
      Prowl.stub_any_instance(:perform, 200) do
        notification.run("alarm_sounding" => true)
      end

      # This isn't using the stubbed version of Prowl and if a notification is
      # sent will raise an error, resulting in a failed test
      #
      notification.run("alarm_sounding" => true)
    end

    it 'does not send a notification when there is no alarm' do
      # This isn't using the stubbed version of Prowl and if a notification is
      # sent will raise an error, resulting in a failed test
      #
      notification.run({})
    end

    it 'sends two notifications for back to back alarms' do
      # ALARM
      #
      Prowl.stub_any_instance(:perform, 200) do
        notification.run("alarm_sounding" => true)
      end

      # All clear
      #
      notification.run({})

      redis.lrange("alarm-notified-prowl", 0, -1).must_equal []

      # ALARM
      #
      Prowl.stub_any_instance(:perform, 200) do
        notification.run("alarm_sounding" => true)
      end

      redis.lrange("alarm-notified-prowl", 0, -1).must_equal @config['prowl']
    end
  end

  describe "mail" do
    Mail.defaults do
      delivery_method :test
    end

    before do
      @config = {
        "emails" => ["jordan@test.com", "kelly@test.com"],
        "from_address" => "alarm@test.com"
      }

      Mail::TestMailer.deliveries.clear

      redis.del "alarm-notified-email"
    end

    it 'sends no emails when no emails specified' do
      @config = {}

      notification.run("alarm_sounding" => true)

      Mail::TestMailer.deliveries.count.must_equal 0
    end

    it 'sends a email when there is an alarm' do
      notification.run("alarm_sounding" => true)

      Mail::TestMailer.deliveries.count.must_equal 2
    end

    it 'only sends one message per email per alarm' do
      notification.run("alarm_sounding" => true)

      # This isn't using the stubbed version of Prowl and if a notification is
      # sent will raise an error, resulting in a failed test
      #
      notification.run("alarm_sounding" => true)

      Mail::TestMailer.deliveries.count.must_equal 2
    end

    it 'does not send an email when there is no alarm' do
      notification.run({})

      Mail::TestMailer.deliveries.count.must_equal 0
    end

    it 'sends two notifications for back to back alarms' do
      # ALARM
      #
      notification.run("alarm_sounding" => true)

      # All clear
      #
      notification.run({})

      Mail::TestMailer.deliveries.count.must_equal 2

      # ALARM
      #
      notification.run("alarm_sounding" => true)

      Mail::TestMailer.deliveries.count.must_equal 4
    end
  end
end
