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

pub fn (mut sm SoundManager) play_step() {
	count := int(audio_sample_rate * 0.04)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 180.0
		env := 1.0 - (t / 0.04)
		val := i16(math.sin(2.0 * math.pi * freq * t) * env * 12000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_climb() {
	count := int(audio_sample_rate * 0.08)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 260.0 + (t / 0.08) * 160.0
		env := 1.0 - (t / 0.08)
		val := i16(math.sin(2.0 * math.pi * freq * t) * env * 14000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_pickup() {
	count := int(audio_sample_rate * 0.1)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 400.0 + (t / 0.1) * 300.0
		env := 1.0 - (t / 0.1)
		val := i16(math.sin(2.0 * math.pi * freq * t) * env * 15000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_drop() {
	count := int(audio_sample_rate * 0.08)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 280.0 - (t / 0.08) * 120.0
		env := 1.0 - (t / 0.08)
		val := i16(math.sin(2.0 * math.pi * freq * t) * env * 16000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_win() {
	count := int(audio_sample_rate * 0.45)
	mut samples := []i16{cap: count}
	notes := [440.0, 554.37, 659.25, 880.0]
	note_len := count / notes.len
	for i in 0 .. count {
		note_idx := i / note_len
		freq := if note_idx < notes.len { notes[note_idx] } else { 880.0 }
		t := f64(i) / f64(audio_sample_rate)
		val := i16(math.sin(2.0 * math.pi * freq * t) * 14000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_restart() {
	count := int(audio_sample_rate * 0.15)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 500.0 - (t / 0.15) * 300.0
		env := 1.0 - (t / 0.15)
		val := i16(math.sin(2.0 * math.pi * freq * t) * env * 14000.0)
		samples << val
	}
	sm.play_samples(samples)
}
