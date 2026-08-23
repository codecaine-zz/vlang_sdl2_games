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
	return sm
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

pub fn (mut sm SoundManager) play_claw_shoot_sound() {
	count := int(audio_sample_rate * 0.1)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 300.0 + 200.0 * (t / 0.1)
		env := 1.0 - (t / 0.1)
		val := i16(math.sin(2.0 * math.pi * freq * t) * env * 16000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_gold_catch_sound() {
	notes := [659.25, 880.0, 1046.50]
	note_dur := 0.08
	count := int(audio_sample_rate * note_dur * f64(notes.len))
	mut samples := []i16{cap: count}
	for freq in notes {
		sub_count := int(audio_sample_rate * note_dur)
		for i in 0 .. sub_count {
			t := f64(i) / f64(audio_sample_rate)
			env := math.exp(-8.0 * t)
			val := i16(math.sin(2.0 * math.pi * freq * t) * env * 22000.0)
			samples << val
		}
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_dynamite_sound() {
	count := int(audio_sample_rate * 0.3)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		noise := (f64(rand.intn(200) or { 100 }) - 100.0) / 100.0
		env := math.exp(-6.0 * t)
		val := i16(noise * env * 26000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_coin_sound() {
	notes := [880.0, 1174.66]
	note_dur := 0.09
	count := int(audio_sample_rate * note_dur * f64(notes.len))
	mut samples := []i16{cap: count}
	for freq in notes {
		sub_count := int(audio_sample_rate * note_dur)
		for i in 0 .. sub_count {
			t := f64(i) / f64(audio_sample_rate)
			env := math.exp(-6.0 * t)
			val := i16(math.sin(2.0 * math.pi * freq * t) * env * 22000.0)
			samples << val
		}
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_win_sound() {
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_dur := 0.12
	count := int(audio_sample_rate * note_dur * f64(notes.len))
	mut samples := []i16{cap: count}
	for freq in notes {
		sub_count := int(audio_sample_rate * note_dur)
		for i in 0 .. sub_count {
			t := f64(i) / f64(audio_sample_rate)
			env := 1.0 - (t / note_dur)
			val := i16((math.sin(2.0 * math.pi * freq * t) * 0.7 + math.sin(4.0 * math.pi * freq * t) * 0.3) * env * 20000.0)
			samples << val
		}
	}
	sm.play_samples(samples)
}
