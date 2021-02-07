require "./src/audio"

puts "hello"
Audio.init

devices = Audio::Device.scan
puts "num of devices: #{devices.size}"


filename = "#{File.dirname(__FILE__)}/spec/fixtures/fine.wav"

puts "#{filename} Exists - #{File.exists?(filename)}"

file = Audio::File.new(filename)
file.play








