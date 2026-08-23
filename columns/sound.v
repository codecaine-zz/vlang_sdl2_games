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

// Crisp cycling chime when cycling gems in the falling column
fn (sm &SoundManager) play_cycle_sound() {
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 600.0 + t * 4000.0
		env := 1.0 - (f64(i) / f64(num_samples))
		sine := math.sin(2.0 * math.pi * freq * t)
		tri := if (int(t * freq * 2.0) % 2) == 0 { 1.0 } else { -1.0 }
		sample := (sine * 0.7 + tri * 0.3) * env * 12000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Movement tick
fn (sm &SoundManager) play_move_sound() {
	sample_rate := 44100
	duration_ms := 25
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 420.0
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 9000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Column landing / lock click
fn (sm &SoundManager) play_land_sound() {
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 220.0 * (1.0 - t * 4.0)
		if freq < 60.0 {
			continue
		}
		env := math.exp(-t * 28.0)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 16000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Jewel Match / Pop chime with pitch scaling for combos
fn (sm &SoundManager) play_match_sound(combo int) {
	sample_rate := 44100
	duration_ms := 150 + combo * 30
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	base_freq := 523.25 * math.pow(1.12246, f64(combo - 1)) // C5 upwards

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-t * 12.0)
		s1 := math.sin(2.0 * math.pi * base_freq * t)
		s2 := math.sin(2.0 * math.pi * base_freq * 1.5 * t) * 0.5
		s3 := math.sin(2.0 * math.pi * base_freq * 2.0 * t) * 0.3
		sample := (s1 + s2 + s3) * env * 18000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Magic Gem explosion / rainbow laser sweep
fn (sm &SoundManager) play_magic_sound() {
	sample_rate := 44100
	duration_ms := 380
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 300.0 + math.sin(t * 45.0) * 200.0 + t * 900.0
		env := (1.0 - (f64(i) / f64(num_samples))) * (1.0 - math.exp(-t * 40.0))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 19000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Game Over descending tone
fn (sm &SoundManager) play_game_over_sound() {
	sample_rate := 44100
	duration_ms := 500
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 350.0 - t * 450.0
		if freq < 40.0 {
			break
		}
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 15000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}
