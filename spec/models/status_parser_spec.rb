require_relative '../spec_helper'

describe AlarmDecoder::StatusParser do
  let(:raw_status) { %{[1000000110000000----],001,} +
                     %{[f70000008001001c28000000000000],} +
                     %{" DISARMED CHIME   Ready to Arm  "} }
  let(:malformed_status) { "1234" }
  let(:parser) { AlarmDecoder::StatusParser.new(raw_status) }

  it 'parses the bit field' do
    parser.status[:ready].must_equal true
    parser.status[:armed_away].must_equal false
    parser.status[:armed_home].must_equal false
    parser.status[:alarm_occured].must_equal false
    parser.status[:alarm_sounding].must_equal false
    parser.status[:armed_instant].must_equal false
    parser.status[:fire].must_equal false
    parser.status[:zone_issue].must_equal false
    parser.status[:perimeter_only].must_equal false
  end

  it 'parses the zone number' do
    parser.status[:zone_number].must_equal 1
  end

  it 'parses the zone name if ALARM_DECODER_CONFIG is present' do
    ENV['ALARM_DECODER_CONFIG'] = File.join(__dir__, '../support/config.yml')
    parser.status[:zone_name].must_equal "Front Door"
  end

  it 'omits the zone name if ALARM_DECODER_CONFIG is missing' do
    ENV['ALARM_DECODER_CONFIG'] = nil
    parser.status[:zone_name].must_be_nil
  end

  it 'includes the display message' do
    parser.status[:display_message].must_equal(
      %{" DISARMED CHIME   Ready to Arm  "})
  end

  it 'returns nil for missing or malformed statuses' do
    parser = AlarmDecoder::StatusParser.new(malformed_status)

    parser.status.must_be_nil
  end
end
