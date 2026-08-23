module main

import math
import sdl

pub struct SoundManager {
pub mut:
	audio_device u32
	sound_on     bool = true
}

pub fn new_sound_manager() SoundManager {
	return SoundManager{}
}

pub fn (mut sm SoundManager) init() {
	spec := sdl.AudioSpec{
		freq:     44100
		format:   sdl.AudioFormat(sdl.audio_s16lsb)
		channels: 1
		samples:  1024
		callback: unsafe { nil }
	}
	sm.audio_device = sdl.open_audio_device(unsafe { nil }, 0, &spec, unsafe { nil }, 0)
	if sm.audio_device > 0 {
		sdl.pause_audio_device(sm.audio_device, 0)
	}
}

pub fn (mut sm SoundManager) toggle_sound() {
	sm.sound_on = !sm.sound_on
}

fn (sm &SoundManager) play_beep(freq f64, duration_ms int) {
	if !sm.sound_on || sm.audio_device == 0 {
		return
	}
	sample_rate := 44100
	num_samples := sample_rate * duration_ms / 1000
	mut buffer := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		val := math.sin(2.0 * math.pi * freq * t)
		// Square wave harmonic for retro LCD buzzer
		sample := if val >= 0.0 { i16(4000) } else { i16(-4000) }
		buffer[i] = sample
	}

	sdl.queue_audio(sm.audio_device, buffer.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_btn_click() {
	sm.play_beep(1200.0, 30)
}

pub fn (sm &SoundManager) play_eat_sound() {
	sm.play_beep(600.0, 60)
	sm.play_beep(850.0, 60)
}

pub fn (sm &SoundManager) play_happy_sound() {
	sm.play_beep(800.0, 50)
	sm.play_beep(1000.0, 50)
	sm.play_beep(1400.0, 80)
}

pub fn (sm &SoundManager) play_alert_sound() {
	sm.play_beep(1500.0, 80)
	sm.play_beep(1200.0, 80)
}
