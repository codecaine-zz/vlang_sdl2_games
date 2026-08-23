module main

import math
import sdl

struct SoundManager {
mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
}

fn new_sound_manager() SoundManager {
	if sdl.was_init(sdl.init_audio) == 0 {
		sdl.init_sub_system(sdl.init_audio)
	}

	desired := sdl.AudioSpec{
		freq:     44100
		format:   sdl.audio_s16
		channels: 1
		samples:  1024
		callback: unsafe { nil }
		userdata: unsafe { nil }
	}
	mut obtained := sdl.AudioSpec{}
	dev_id := sdl.open_audio_device(unsafe { nil }, 0, &desired, &obtained, 0)
	if dev_id != 0 {
		sdl.pause_audio_device(dev_id, 0)
	}

	return SoundManager{
		dev:           dev_id
		sound_enabled: dev_id != 0
	}
}

fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	return mutable_sm.sound_enabled
}

fn (sm &SoundManager) play_pcm(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

// Cluster hover tick
fn (sm &SoundManager) play_hover_sound() {
	sample_rate := 44100
	duration_ms := 20
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 700.0
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 6000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Cluster shatter explosion (glass crunch & chimes)
fn (sm &SoundManager) play_shatter_sound(cluster_size int) {
	sample_rate := 44100
	mut duration_ms := 150 + cluster_size * 15
	if duration_ms > 450 {
		duration_ms = 450
	}
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	base_freq := 380.0 + f64(cluster_size) * 35.0

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-t * 12.0)
		s1 := math.sin(2.0 * math.pi * base_freq * t)
		s2 := math.sin(2.0 * math.pi * (base_freq * 1.5) * t) * 0.6
		noise := (f64(i % 19) / 9.5 - 1.0) * 0.35
		sample := (s1 + s2 + noise) * env * 17000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Gravity drop settle
fn (sm &SoundManager) play_drop_sound() {
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 220.0
		env := math.exp(-t * 35.0)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 11000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Full board clear victory fanfare
fn (sm &SoundManager) play_clear_all_sound() {
	sample_rate := 44100
	duration_ms := 600
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		step := int(t * 10.0)
		freq := 523.25 * math.pow(1.12246, f64(step * 2))
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 17000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Game over
fn (sm &SoundManager) play_game_over_sound() {
	sample_rate := 44100
	duration_ms := 450
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 320.0 - t * 400.0
		if freq < 40.0 {
			break
		}
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 15000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}
