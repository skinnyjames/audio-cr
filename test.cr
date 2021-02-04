require "./src/audio"

puts "hello"
Audio.init
devices = Audio::Device.scan.map &.name
puts "devices: #{devices.join(",")}"