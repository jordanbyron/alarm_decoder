$:.push File.expand_path("../lib", __FILE__)

require "alarm_decoder/version"

Gem::Specification.new do |s|
  s.name        = "alarm_decoder"
  s.version     = AlarmDecoder::VERSION
  s.authors     = ["Jordan Byron"]
  s.email       = ["jordan.byron@gmail.com"]
  s.homepage    = "https://github.com/jordanbyron/alarm_decoder"
  s.summary     = "Alarm Decoder w/ Redis backend"
  s.description = "Tools to work with Nu Tech Software Solution's Alarm Decoder AD2USB devices"

  s.files = Dir["{bin,lib}/**/*"] +
    %w{Rakefile README.md LICENSE}

  s.add_dependency "serialport", ">= 1.3.0"
  s.add_dependency "prowl", ">= 0.1.3"
  s.add_dependency "redis", ">= 3.0.7"
  s.add_dependency "highline", ">= 1.6.20"
  s.add_dependency "mail"

  s.add_development_dependency "minitest", ">= 5.4.2", "~> 5.4.0"
  s.add_development_dependency "minitest-stub_any_instance"
  s.add_development_dependency "pry"
end
