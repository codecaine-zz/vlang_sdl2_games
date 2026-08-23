module main

import math
import rand
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

fn (sm &SoundManager) play_sound_raw(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

// Satisfying mechanical keyboard switch click + laser blast
fn (sm &SoundManager) play_laser_zap(char_idx int) {
	sample_rate := 44100
	duration_ms := 45
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	base_freq := 600.0 + f64(char_idx % 8) * 90.0

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := base_freq - (t * 4500.0)
		env := math.exp(-35.0 * t)
		click := (rand.f64() * 2.0 - 1.0) * math.exp(-80.0 * t) * 0.3
		val := (math.sin(2.0 * math.pi * math.max(80.0, freq) * t) * 0.6 + click) * env * 0.45
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

// Misfire / wrong key press chirp
fn (sm &SoundManager) play_misfire() {
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 160.0 - (t * 800.0)
		env := math.exp(-40.0 * t)
		val := math.sin(2.0 * math.pi * math.max(40.0, freq) * t) * env * 0.3
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

// Word fully typed & destroyed combo chime
fn (sm &SoundManager) play_word_complete(combo int) {
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	base_note := notes[math.min(combo - 1, notes.len - 1)]

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := base_note + (t * 1200.0)
		env := 1.0 - (f64(i) / f64(num_samples))
		val := math.sin(2.0 * math.pi * freq * t) * env * 0.4
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

// Enemy craft explosion
fn (sm &SoundManager) play_enemy_explosion() {
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * 0.7
		freq := 120.0 - (t * 300.0)
		env := math.exp(-9.0 * t)
		val := (math.sin(2.0 * math.pi * math.max(30.0, freq) * t) * 0.5 + noise) * env * 0.5
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

// EMP Screen-clearing shockwave boom
fn (sm &SoundManager) play_emp_blast() {
	sample_rate := 44100
	duration_ms := 450
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1400.0 - (t * 2600.0) + math.sin(t * 80.0) * 300.0
		noise := (rand.f64() * 2.0 - 1.0) * 0.3
		env := math.exp(-5.5 * t)
		val := (math.sin(2.0 * math.pi * math.max(40.0, freq) * t) * 0.7 + noise) * env * 0.55
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

// Time freeze or shield powerup
fn (sm &SoundManager) play_powerup() {
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	notes := [440.0, 554.37, 659.25, 880.0]
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		n_idx := math.min(int(t * 22.0), notes.len - 1)
		freq := notes[n_idx]
		env := 1.0 - (f64(i) / f64(num_samples))
		val := math.sin(2.0 * math.pi * freq * t) * env * 0.4
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

// Hull damage alarm
fn (sm &SoundManager) play_damage() {
	sample_rate := 44100
	duration_ms := 250
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := if int(t * 16.0) % 2 == 0 { 400.0 } else { 220.0 }
		noise := (rand.f64() * 2.0 - 1.0) * 0.3
		env := math.exp(-6.0 * t)
		val := (math.sin(2.0 * math.pi * freq * t) * 0.6 + noise) * env * 0.5
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

// Wave victory fanfare
fn (sm &SoundManager) play_wave_clear() {
	sample_rate := 44100
	duration_ms := 550
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		n_idx := math.min(int(t * 9.0), notes.len - 1)
		freq := notes[n_idx]
		env := 1.0 - (f64(i) / f64(num_samples))
		val := math.sin(2.0 * math.pi * freq * t) * env * 0.45
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}
