require "soundfile"

module Audio
  class AudioData


    @frames : Int64
    @frame_count : Int32
    @ring_buffer_data : Float64 | Nil
    @ring_buffer : LibPortAudio::PaUtilRingBuffer

    property :buffer, :sample_rate, :channels, :frames, :thread_sync_flag, :read_complete, :ring_buffer
    getter :frame_count
    setter :frame_count

    def initialize
      @buffer = 0
      @sample_rate = 44100
      @channels = 2
      @frames = 0
      @thread_sync_flag = 0
      @read_complete = 0
      @frame_count = 0_i32
      @ring_buffer = LibPortAudio::PaUtilRingBuffer.new
      @ring_buffer_data = 0
    end

    def ring_buffer_ptr
      pointerof(@ring_buffer)
    end

    def ring_buffer_data=(val : Float64 | Nil)
      @ring_buffer_data = val
    end

    def ring_buffer_data
      @ring_buffer_data
    end

    def ring_buffer_data_ptr : Pointer(Void) | Nil
      @ring_buffer_data.try { |data| Box.box(data) } 
    end
  end

  class File < SoundFile::SFile
    getter :path
    property :audio_data

    def initialize(path : String, audio_data = AudioData.new)
      @path = path
      @audio_data = audio_data
      super()
    end

    def play(output_device : Audio::Device = Audio::Device.default_output)
      open(@path, :read)
      audio_data.channels = channels
      audio_data.sample_rate = sample_rate
      audio_data.frames = frames

      next_power_of_two = -> (val : UInt32) {
        val -= 1
        val = (val >> 1) | val
        val = (val >> 2) | val;
        val = (val >> 4) | val;
        val = (val >> 8) | val;
        val = (val >> 16) | val;
        val += 1
      }

      sample_calc = audio_data.sample_rate * 0.5 * audio_data.channels

      number_of_samples = next_power_of_two.call(sample_calc.to_u32)
      
      audio_data.ring_buffer_data = LibPortAudio.allocate_memory(number_of_samples.to_f64)

      clean if audio_data.ring_buffer_data.nil?

      audio_data.ring_buffer_data_ptr.try do |data_ptr|
        LibPortAudio.initialize_ring_buffer(audio_data.ring_buffer_ptr, sizeof(Float64), number_of_samples, data_ptr)

        ptr = Pointer(Void).new(audio_data.object_id)
        
        spawn do 
          Audio::Device.buffer_audio_file(audio_data, self)
        end
      
        output_device.stream(ptr)

      end
    end

    def clean
      close 
      audio_data.ring_buffer_data.try {|data| LibPortAudio.free_memory(data) }
    end
  end
end