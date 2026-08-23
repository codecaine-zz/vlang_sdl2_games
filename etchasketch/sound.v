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
	if !sm.enabled && sm.dev_id != 0 {
		sdl.clear_queued_audio(sm.dev_id)
	}
	return sm.enabled
}

fn (mut sm SoundManager) play_samples(samples []i16) {
	if !sm.enabled || sm.dev_id == 0 || samples.len == 0 {
		return
	}
	// Limit queue size to avoid latency build-up
	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued > u32(audio_sample_rate * int(sizeof(i16)) / 4) {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

// Gentle mechanical click for rotary knobs
pub fn (mut sm SoundManager) play_knob_click(is_vertical bool) {
	dur := 0.018
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	freq := if is_vertical { 980.0 } else { 820.0 }

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 220.0)
		s1 := math.sin(2.0 * math.pi * freq * t)
		s2 := math.sin(2.0 * math.pi * (freq * 0.5) * t) * 0.3
		val := i16((s1 + s2) * env * 9000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Subtle stylus pencil glide friction
pub fn (mut sm SoundManager) play_scratch() {
	dur := 0.025
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 120.0)
		s := math.sin(2.0 * math.pi * 420.0 * t)
		val := i16(s * env * 4500.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Smooth powder shake swirl sound
pub fn (mut sm SoundManager) play_shake_whoosh() {
	dur := 0.45
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.sin(math.pi * (t / dur))
		f := 120.0 + math.sin(2.0 * math.pi * 3.0 * t) * 40.0
		s := math.sin(2.0 * math.pi * f * t)
		val := i16(s * env * 12000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Warm soft musical chime
pub fn (mut sm SoundManager) play_chime(note int) {
	dur := 0.18
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	freq := 440.0 * math.pow(1.05946, f64(note))

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 16.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 11000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Level complete victory chime
pub fn (mut sm SoundManager) play_success_fanfare() {
	dur := 0.35
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	freqs := [523.25, 659.25, 783.99, 1046.50]

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		idx := int(t / 0.085)
		freq := if idx < freqs.len { freqs[idx] } else { freqs.last() }
		local_t := math.fmod(t, 0.085)
		env := math.exp(-local_t * 18.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 12000.0)
		samples << val
	}
	sm.play_samples(samples)
}
