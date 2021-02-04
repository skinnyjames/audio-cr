require "soundio"

module Audio
  VERSION = "0.1.0"
  @@soundio : (Pointer(LibSoundIo::SoundIo) | Nil)

  def self.init
    check soundio
    err = LibSoundIo.connect soundio
    raise "#{LibSoundIo.strerror(err)}" if err < 0
    flush
  end

  def self.flush
    LibSoundIo.flush_events(soundio)
  end

  def self.soundio
    @@soundio ||= LibSoundIo.create
  end

  def self.check(io = soundio)
    if io == Pointer(LibSoundIo::SoundIo).null
      raise "Out of Memory"
    end
  end
end

require "./audio/device"
require "./audio/file"
