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

pub fn (mut sm SoundManager) play_hop_sound() {
	count := int(audio_sample_rate * 0.1)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 220.0 + 380.0 * (t / 0.1)
		env := 1.0 - (t / 0.1)
		val := i16(math.sin(2.0 * math.pi * freq * t) * env * 18000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_disc_sound() {
	count := int(audio_sample_rate * 0.4)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 300.0 + 500.0 * math.sin(t * 20.0)
		env := 1.0 - (t / 0.4)
		val := i16(math.sin(2.0 * math.pi * freq * t) * env * 20000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_curse_sound() {
	count := int(audio_sample_rate * 0.35)
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		rand_pitch := 180.0 + f64((i / 400) % 7) * 90.0
		env := 1.0 - (t / 0.35)
		val := i16((math.sin(2.0 * math.pi * rand_pitch * t) + f64(rand.intn(100) or { 0 }) / 100.0 * 0.4) * env * 22000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_win_sound() {
	notes := [440.0, 554.37, 659.25, 880.0]
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
