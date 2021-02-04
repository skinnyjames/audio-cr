module Audio
  class Device
    def self.scan
      count_index = LibSoundIo.output_device_count(Audio.soundio) - 1
      (0..count_index).to_a.map do |index|
        new(index)
      end
    end

    def self.flush
      LibSoundIo.flush_events(Audio.soundio)
    end

    def initialize(device_index : Int32 = LibSoundIo.default_output_device_index(Audio.soundio))
      @device_index = device_index
      @device = LibSoundIo.get_output_device(Audio.soundio, device_index)
    end

    def name
      String.new @device.value.name
    end
  end
end
