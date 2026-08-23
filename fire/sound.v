module main

import math
import sdl

const audio_sample_rate = 44100

pub struct SoundManager {
pub mut:
	dev_id  u32
	enabled bool = true
}

pub fn new_sound_manager() SoundManager {
	mut sm := SoundManager{}
	sm.init()
	return sm
}

pub fn (mut sm SoundManager) init() {
	if sm.dev_id != 0 {
		return
	}
	if sdl.was_init(sdl.init_audio) == 0 {
		sdl.init_sub_system(sdl.init_audio)
	}
	spec := sdl.AudioSpec{
		freq:     audio_sample_rate
		format:   sdl.AudioFormat(sdl.audio_s16sys)
		channels: 1
		samples:  1024
		callback: unsafe { nil }
	}
	obtained := sdl.AudioSpec{}
	dev := sdl.open_audio_device(unsafe { nil }, 0, &spec, &obtained, 0)
	if dev > 0 {
		sm.dev_id = dev
		sdl.pause_audio_device(dev, 0)
	}
}

pub fn (mut sm SoundManager) toggle_sound() {
	sm.enabled = !sm.enabled
}

fn (mut sm SoundManager) play_samples(samples []i16) {
	if !sm.enabled || sm.dev_id == 0 || samples.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

pub fn (mut sm SoundManager) play_tick() {
	count := int(audio_sample_rate * 0.03)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 1200.0
		val := i16(if (math.sin(2.0 * math.pi * freq * t)) > 0 { 10000.0 } else { -10000.0 })
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_bounce() {
	count := int(audio_sample_rate * 0.06)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 880.0 + (t / 0.06) * 440.0
		val := i16(if (math.sin(2.0 * math.pi * freq * t)) > 0 { 12000.0 } else { -12000.0 })
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_score() {
	count := int(audio_sample_rate * 0.12)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := if i < count / 2 { 1046.50 } else { 1318.51 }
		val := i16(if (math.sin(2.0 * math.pi * freq * t)) > 0 { 13000.0 } else { -13000.0 })
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_miss() {
	count := int(audio_sample_rate * 0.25)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 180.0
		val := i16(if (math.sin(2.0 * math.pi * freq * t)) > 0 { 14000.0 } else { -14000.0 })
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_game_over() {
	count := int(audio_sample_rate * 0.5)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 440.0 - (t / 0.5) * 280.0
		val := i16(if (math.sin(2.0 * math.pi * freq * t)) > 0 { 12000.0 } else { -12000.0 })
		samples << val
	}
	sm.play_samples(samples)
}
