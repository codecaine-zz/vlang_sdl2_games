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

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.enabled = !sm.enabled
	return sm.enabled
}

fn (mut sm SoundManager) play_samples(samples []i16) {
	if !sm.enabled || sm.dev_id == 0 || samples.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

pub fn (mut sm SoundManager) play_ski_glide() {
	dur := 0.08
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := (1.0 - t / dur)
		noise := (rand.f64() * 2.0 - 1.0)
		val := i16(noise * env * 5000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_jump() {
	dur := 0.18
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := (1.0 - t / dur)
		freq := 280.0 + (t / dur) * 450.0
		val := i16(math.sin(2.0 * math.pi * freq * t) * env * 14000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_trick_chime() {
	dur := 0.25
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	notes := [659.25, 783.99, 987.77, 1318.51]

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		n_idx := int(t / (dur / 4.0))
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		local_t := math.fmod(t, dur / 4.0)
		env := math.exp(-local_t * 24.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 15000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_crash() {
	dur := 0.35
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 12.0)
		noise := (rand.f64() * 2.0 - 1.0)
		thud := math.sin(2.0 * math.pi * 80.0 * t)
		val := i16((noise * 0.7 + thud * 0.3) * env * 22000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_gate_bell() {
	dur := 0.2
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	freq := 1760.0 // A6 high chime

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 18.0)
		val := i16(math.sin(2.0 * math.pi * freq * t) * env * 16000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_yeti_roar() {
	dur := 0.6
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.sin(math.pi * (t / dur))
		mod := math.sin(2.0 * math.pi * 18.0 * t) * 35.0
		freq := 95.0 + mod
		noise := (rand.f64() * 2.0 - 1.0) * 0.4
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16((s * 0.6 + noise) * env * 24000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_yeti_crunch() {
	dur := 0.4
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 8.0)
		noise := (rand.f64() * 2.0 - 1.0)
		val := i16(noise * env * 22000.0)
		samples << val
	}
	sm.play_samples(samples)
}
