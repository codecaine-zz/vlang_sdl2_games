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

// Tile caught on paddle
fn (sm &SoundManager) play_catch_sound() {
	sample_rate := 44100
	duration_ms := 45
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 340.0 + (1.0 - t * 20.0) * 180.0
		env := math.exp(-t * 35.0)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 16000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Flip tile into 5x5 bin
fn (sm &SoundManager) play_flip_sound() {
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 520.0 - t * 4000.0
		if freq < 80.0 {
			continue
		}
		env := math.exp(-t * 22.0)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 14000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Push tile back up ramp
fn (sm &SoundManager) play_push_sound() {
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 280.0 + t * 6500.0
		env := (1.0 - (f64(i) / f64(num_samples)))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 13000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Klax line completed! (Chords / celebratory synth chime)
fn (sm &SoundManager) play_klax_sound(combo int) {
	sample_rate := 44100
	duration_ms := 280
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	base_freq := 440.0 * math.pow(1.2599, f64(combo - 1)) // Major 3rd steps

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-t * 8.0)
		s1 := math.sin(2.0 * math.pi * base_freq * t)
		s2 := math.sin(2.0 * math.pi * (base_freq * 1.25) * t) * 0.7
		s3 := math.sin(2.0 * math.pi * (base_freq * 1.5) * t) * 0.5
		sample := (s1 + s2 + s3) * env * 17000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Tile dropped off end (Buzzer)
fn (sm &SoundManager) play_drop_loss_sound() {
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 110.0
		sqr := if (int(t * freq * 2.0) % 2) == 0 { 1.0 } else { -1.0 }
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := sqr * env * 16000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Wave victory fanfare
fn (sm &SoundManager) play_wave_clear_sound() {
	sample_rate := 44100
	duration_ms := 400
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		step := int(t * 12.0)
		freq := 523.25 * math.pow(1.12246, f64(step * 2))
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 16000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Game over
fn (sm &SoundManager) play_game_over_sound() {
	sample_rate := 44100
	duration_ms := 480
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
