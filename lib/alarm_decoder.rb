require 'serialport'
require 'redis'
require 'thread'
require 'json'

module AlarmDecoder
  PORT      = "/dev/tty.usbserial-A1018WSP"
  BAUD      = 115200
  DATA_BITS = 8

  def self.redis
    Redis.new
  end

  def self.listen
    interrupted = false
    trap("INT") do
      interrupted = true
      puts "Quitting"
    end

    SerialPort.open(PORT, "baud" => BAUD, "data_bits" => DATA_BITS) do |sp|
      write_thread = Thread.new do
        redis.subscribe 'alarm_decoder_write' do |on|
          on.message do |channel, message|
            sp.puts message
          end
        end
      end
      while (i = sp.gets.chomp) && !interrupted do
        puts i
        if message = parse_message(i)
          redis.publish 'alarm_decoder', message.to_json
        end
      end
      write_thread.kill
    end
  end

  def self.watch
    redis.subscribe 'alarm_decoder' do |on|
      on.message do |channel, message|
        yield JSON.parse(message)
      end
    end
  end

  def self.write(message)
    redis.publish 'alarm_decoder_write', message
  end

  private

  def self.parse_message(raw_message)
    return unless raw_message[/\[/]
    bit_field = raw_message.split(',').first.gsub(/\[|\]/, '').chars.map(&:to_i)
    {
      "READY"          => bit_field[0] == 1,
      "ARMED AWAY"     => bit_field[1] == 1,
      "ARMED HOME"     => bit_field[2] == 1,
      "ALARM OCCURED"  => bit_field[10] == 1,
      "ALARM SOUNDING" => bit_field[11] == 1,
      "ARMED INSTANT"  => bit_field[13] == 1,
      "PERIMETER ONLY" => bit_field[16] == 1
    }
  end
end
