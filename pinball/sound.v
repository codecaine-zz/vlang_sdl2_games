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
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

fn (sm &SoundManager) play_flick() {
	sample_rate := 44100
	duration_ms := 35
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 420.0 + (t * 6000.0)
		env := math.exp(-35.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
		pcm[i] = i16(harm * env * attack * 16000.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_bumper() {
	sample_rate := 44100
	duration_ms := 90
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 920.0 - (t * 4000.0)
		env := math.exp(-22.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * math.max(140.0, freq) * t) + 0.35 * math.sin(4.0 * math.pi * math.max(140.0, freq) * t)
		pcm[i] = i16(harm * env * attack * 22000.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_slingshot() {
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 640.0 + (t * 2600.0)
		noise := (rand.f64() * 2.0 - 1.0) * 0.2
		env := math.exp(-22.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := (math.sin(2.0 * math.pi * freq * t) * 0.8 + noise)
		pcm[i] = i16(harm * env * attack * 18000.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_target() {
	sample_rate := 44100
	duration_ms := 90
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1250.0 + (t * 2000.0)
		env := math.exp(-18.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)
		pcm[i] = i16(harm * env * attack * 18000.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_spinner() {
	sample_rate := 44100
	duration_ms := 25
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1850.0
		env := math.exp(-45.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * attack * 14000.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_mario_bounce() {
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 320.0 + (t * 3200.0)
		env := math.exp(-14.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
		pcm[i] = i16(harm * env * attack * 20000.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_damsel_rescue() {
	sample_rate := 44100
	duration_ms := 380
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	notes := [523.25, 659.25, 783.99, 1046.50] // C5, E5, G5, C6
	note_len := num_samples / notes.len
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		note_idx := math.min(i / note_len, notes.len - 1)
		freq := notes[note_idx]
		local_i := i % note_len
		local_t := f64(local_i) / f64(sample_rate)
		env := math.exp(-12.0 * local_t)
		attack := if local_i < attack_samples { f64(local_i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * local_t) + 0.35 * math.sin(4.0 * math.pi * freq * local_t)
		pcm[i] = i16(harm * env * attack * 20000.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_drain() {
	sample_rate := 44100
	duration_ms := 280
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 620.0 - (t * 1600.0)
		env := math.exp(-7.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		pcm[i] = i16(math.sin(2.0 * math.pi * math.max(60.0, freq) * t) * env * attack * 20000.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_plunger_release() {
	sample_rate := 44100
	duration_ms := 140
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 160.0 + (t * 2400.0)
		env := math.exp(-12.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)
		pcm[i] = i16(harm * env * attack * 22000.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_tilt() {
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 180.0
		env := math.exp(-8.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		val := if math.sin(2.0 * math.pi * freq * t) > 0 { 0.7 } else { -0.7 }
		pcm[i] = i16(val * env * attack * 20000.0)
	}
	sm.play_sound_raw(pcm)
}
