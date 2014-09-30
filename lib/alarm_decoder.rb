require 'serialport'
require 'redis'
require 'thread'
require 'json'

require_relative 'alarm_decoder/status_parser'

module AlarmDecoder
  PORT = ENV['ALARM_DECODER_PORT']
  BAUD = ENV['ALARM_DECODER_BAUD'] || 115200

  def self.listen(redis = Redis.new)
    interrupted = false
    trap("INT") do
      interrupted = true
      puts "Quitting"
    end

    SerialPort.open(PORT, "baud" => BAUD) do |sp|

      # Write Thread
      #
      write_thread = Thread.new do
        begin
          write_redis = Redis.new
          write_redis.subscribe 'alarm_decoder_write' do |on|
            on.message do |channel, message|
              sp.puts message
            end
          end
        rescue Redis::BaseConnectionError => error
          puts "Write Thread: #{error}, retrying in 1s"
          sleep 1
          retry
        end
      end

      # Read Loop
      #
      while (i = sp.gets.chomp) && !interrupted do
        puts i
        if status = StatusParser.new(i).status
          redis.publish 'alarm_decoder', status.to_json
        end
      end
      write_thread.kill
    end
  end

  def self.watch(redis = Redis.new)
    redis.subscribe 'alarm_decoder' do |on|
      on.message do |channel, message|
        yield JSON.parse(message)
      end
    end
  rescue Redis::BaseConnectionError => error
    puts "#{error}, retrying in 1s"
    sleep 1
    retry
  end

  def self.write(message, redis = Redis.new)
    redis.publish 'alarm_decoder_write', message
  end
end
