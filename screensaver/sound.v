module main

import math
import rand
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

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.enabled = !sm.enabled
	if !sm.enabled && sm.dev_id != 0 {
		sdl.clear_queued_audio(sm.dev_id)
	}
	return sm.enabled
}

fn (mut sm SoundManager) play_samples(samples []i16) {
	if !sm.enabled || sm.dev_id == 0 || samples.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

pub fn (mut sm SoundManager) play_switch() {
	count := int(audio_sample_rate * 0.05)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 600.0 + (t / 0.05) * 400.0
		val := i16(math.sin(2.0 * math.pi * freq * t) * (1.0 - t / 0.05) * 12000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_matrix_click() {
	count := int(audio_sample_rate * 0.02)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 1800.0 + f64(rand.int_in_range(0, 400) or { 0 })
		val := i16(math.sin(2.0 * math.pi * freq * t) * 10000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_bubble_pop() {
	count := int(audio_sample_rate * 0.08)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 300.0 + (t / 0.08) * 800.0
		val := i16(math.sin(2.0 * math.pi * freq * t) * (1.0 - t / 0.08) * 14000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_laser() {
	count := int(audio_sample_rate * 0.12)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 1200.0 - (t / 0.12) * 900.0
		val := i16(math.sin(2.0 * math.pi * freq * t) * (1.0 - t / 0.12) * 13000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_chiptune_chord() {
	count := int(audio_sample_rate * 0.3)
	mut samples := []i16{cap: count}
	chord := [440.0, 554.37, 659.25]
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		mut mixed := 0.0
		for f in chord {
			mixed += math.sin(2.0 * math.pi * f * t)
		}
		mixed = (mixed / 3.0) * (1.0 - t / 0.3) * 13000.0
		samples << i16(mixed)
	}
	sm.play_samples(samples)
}
