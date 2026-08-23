module main

import math
import rand
import sdl

pub struct SoundManager {
pub mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
}

pub fn new_sound_manager() SoundManager {
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

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.sound_enabled = !sm.sound_enabled
	return sm.sound_enabled
}

// Crisp UI click pop
pub fn (sm &SoundManager) play_click_pop() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 35
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 900.0 - (400.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-60.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 14000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

// Gem mining tap chime
pub fn (sm &SoundManager) play_gem_tap(combo int) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	// Pentatonic notes
	notes := [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51, 1567.98]
	note_idx := math.min(combo, notes.len - 1)
	freq := notes[note_idx]

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-25.0 * t)
		// Bell harmonic
		sample := (math.sin(2.0 * math.pi * freq * t) * 0.7 +
			math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.3) * env * 16000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

// Purchase upgrade cash register / synth jingle
pub fn (sm &SoundManager) play_upgrade_bought() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [659.25, 880.00, 1318.51]
	seg_len := num_samples / 3

	for i in 0 .. num_samples {
		n_idx := math.min(i / seg_len, 2)
		freq := notes[n_idx]
		t_sub := f64(i % seg_len) / f64(sample_rate)
		env := math.exp(-18.0 * t_sub)
		sample := math.sin(2.0 * math.pi * freq * t_sub) * env * 15000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

// Chain reaction bubble detonation with escalating pitch
pub fn (sm &SoundManager) play_chain_pop(chain_count int) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	// Rising tone scale
	freq_base := 240.0 + math.min(f64(chain_count) * 45.0, 1200.0)

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := freq_base + 120.0 * (1.0 - (f64(i) / f64(num_samples)))
		env := math.exp(-15.0 * t)
		harmonic := math.sin(2.0 * math.pi * freq * 1.5 * t) * 0.3
		sample := (math.sin(2.0 * math.pi * freq * t) * 0.7 + harmonic) * env * 18000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

// Whack a mole hammer impact
pub fn (sm &SoundManager) play_whack_impact(is_boss bool) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := if is_boss { 160 } else { 100 }
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		freq := if is_boss { 120.0 } else { 180.0 }
		env := math.exp(-22.0 * t)
		sample := (math.sin(2.0 * math.pi * freq * t) * 0.5 + noise * 0.5) * env * 22000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

// Blade slash woosh & slice
pub fn (sm &SoundManager) play_blade_slice(combo int) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 90
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	slice_freq := 600.0 + f64(combo * 150)

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		f := slice_freq * (1.0 + (f64(i) / f64(num_samples)))
		noise := (rand.f64() * 2.0 - 1.0) * 0.2
		env := math.exp(-20.0 * t)
		sample := (math.sin(2.0 * math.pi * f * t) * 0.8 + noise) * env * 17000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

// Bomb explosion
pub fn (sm &SoundManager) play_explosion() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		freq := 90.0 - (50.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-7.0 * t)
		sample := (math.sin(2.0 * math.pi * freq * t) * 0.3 + noise * 0.7) * env * 24000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

// Golden sparkle / Frenzy trigger
pub fn (sm &SoundManager) play_golden_frenzy() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 320
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 880.0 + 440.0 * math.sin(60.0 * math.pi * t)
		env := math.exp(-6.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 16000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

// Level victory fanfare
pub fn (sm &SoundManager) play_victory() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 400
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50]
	seg_len := num_samples / notes.len

	for i in 0 .. num_samples {
		n_idx := math.min(i / seg_len, notes.len - 1)
		freq := notes[n_idx]
		t_sub := f64(i % seg_len) / f64(sample_rate)
		env := math.exp(-8.0 * t_sub)
		sample := math.sin(2.0 * math.pi * freq * t_sub) * env * 16000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}
