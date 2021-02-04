require "./src/audio"

puts "hello"
Audio.init
num_of_devices = Audio::Device.scan.map &.name
puts "devices: #{num_of_devices.join(",")}"