require "./spec_helper"

Audio.init

describe Audio do
  it "soundio works" do 
    soundio = LibSoundIo.create
    soundio.should_not be_nil  
  end
end

describe Audio do 
  it "should construct" do 
    file = Audio::File.new "fixtures/test.mp3"
    file.responds_to?(:play).should be_true
  end

  describe Audio::Device do 
    it "should scan" do 
      devices = Audio::Device.scan
      devices.size.should be > 0
    end
  end
end