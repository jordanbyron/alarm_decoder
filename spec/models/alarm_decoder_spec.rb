require_relative '../spec_helper'

describe AlarmDecoder do
  before do
    AlarmDecoder.config = {}
  end

  describe 'listen' do
    it 'requires a port' do
      AlarmDecoder.config["baud"] = 8

      ->{
        AlarmDecoder.listen
      }.must_raise TypeError
    end
  end
end
