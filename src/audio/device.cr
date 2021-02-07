module Audio
  class Device < Quartz::Device
    def self.default_input
      new LibPortAudio.get_default_input_device
    end

    def self.default_output
      new LibPortAudio.get_default_output_device
    end

    def self.scan
      (0..Quartz.ndevices - 1).to_a.map do |device_index|
        new(device_index)
      end
    end

    def initialize(device_index : Int32) 
      super(device_index)
    end

    def self.buffer_audio_file(thread_data : Audio::AudioData, file : Audio::File) 
      while true
        available_elements_count = LibPortAudio.get_ring_buffer_write_available(thread_data.ring_buffer_ptr)
        if available_elements_count >= (sizeof(Float64) / 4)

          ptr_1 = Pointer(Float32).malloc(2, 0)
          ptr_void = Box.box(ptr_1.value)
          ptr = pointerof(ptr_void)
          sizes = Pointer(LibPortAudio::RingBufferSizeT).malloc(2, 0)
          
          # data_1 : Float32 = 0.0
          # size_1 : LibPortAudio::RingBufferSizeT = 0
          # data_2 : Float32 = 0.0
          # size_2 : LibPortAudio::RingBufferSizeT = 1

          # data_pointer_1 = Box.box(data_1)
          # data_pointer_2 = Box.box(data_2)
          # size_pointer_1 = pointerof(size_1)
          # size_pointer_2 = pointerof(size_2)

          # data_ptr_ptr_1 = pointerof(data_pointer_1)
          # data_ptr_ptr_2 = pointerof(data_pointer_2)

          LibPortAudio.get_ring_buffer_write_regions(thread_data.ring_buffer_ptr, available_elements_count, ptr + 0, sizes + 0, ptr + 1, sizes + 1)

          items_read_from_file : LibPortAudio::RingBufferSizeT = 0
          iterations = 0

          while iterations < 2 && !ptr[iterations].nil?
            if (sizes[iterations] % thread_data.channels) 
              sizes[iterations] -= sizes[iterations] % thread_data.channels
            end
            address = ptr.address
            value = Box(Float32).unbox(ptr.value)
            new_pointer = Pointer(Float32).new(address)
            items_read_from_file += file.read_float(new_pointer, sizes[iterations]) || 0
            iterations += 1
          end

          # if data_ptr_ptr_1.value
          #   address = data_pointer_1.address
          #   value = Box(Float32).unbox(data_pointer_1)
          #   new_pointer = Pointer(Float32).new(address)
          #   size_1 = size_1 - (size_1 % thread_data.channels) unless (size_1 % thread_data.channels).zero?
          #   items_read_from_file += file.read_float(new_pointer, size_1) || 0
          # end

          # if data_ptr_ptr_2.value
          #   address_2 = data_pointer_2.address
          #   value_2 = Box(Float32).unbox(data_pointer_2)
          #   new_pointer_2 = Pointer(Float32).new(address_2)
          #   size_2 -= (size_2 % thread_data.channels) if (size_2 % thread_data.channels)
          #   items_read_from_file += file.read_float(new_pointer_2, size_2) || 0
          # end

          LibPortAudio.advance_ring_buffer_write_index(thread_data.ring_buffer_ptr, items_read_from_file)
        
          if items_read_from_file > 0
            thread_data.frame_count += (items_read_from_file / thread_data.channels).to_i32
            
            thread_data.read_complete = 1 if thread_data.frame_count == thread_data.frames
          
          else
            thread_data.thread_sync_flag = 1
            break
          end
        end

        LibPortAudio.sleep 0.2
      end
    end

    def stream(ptr : Pointer(Void))

      data = ptr.as(AudioData)

      size = data.frames 
      rate = data.sample_rate
      length = size * rate
      passthrough = -> { ptr }

      @@stream = Quartz::AudioStream(Float32).new(input, output, rate.to_f64, 256.to_u64, true)
      
      
      @@stream.try do |stream| 
        stream.start(passthrough) do |input, output, frames_per_buffer, time_info, status_flags, user_data|

          min = -> (a : Int64, b : Int64) { a < b ? a : b }
          thread_data = Box(Audio::AudioData).unbox(user_data)
          out_buf = output.as(Pointer(Float32))
          new_out = Box.box(out_buf)

          elements_to_play = LibPortAudio.get_ring_buffer_read_available(thread_data.ring_buffer_ptr)
          elements_to_read = min.call(elements_to_play, (frames_per_buffer * thread_data.channels).to_i64)

          ring_buffer = thread_data.ring_buffer
          ring_buffer_ptr = pointerof(ring_buffer)
          
          LibPortAudio.read_ring_buffer(ring_buffer_ptr, new_out, elements_to_read)

          if thread_data.read_complete == 1 && elements_to_play == 0
            1
          else
            0
          end
        end

        while stream.is_active?
          LibPortAudio.sleep 0.3
        end

      end
    end
  end
end