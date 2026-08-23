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
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return mutable_sm.sound_enabled
}

fn (sm &SoundManager) play_pcm(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

fn (sm &SoundManager) play_bomb_drop_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 90
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 340.0 - 180.0 * (f64(i) / f64(num_samples))
		env := math.exp(-22.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)
		pcm[i] = i16(harm * env * attack * 18000.0)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_explosion_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 350
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		low_freq := math.sin(2.0 * math.pi * (110.0 - 70.0 * (f64(i) / f64(num_samples))) * t)
		env := math.exp(-7.5 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		pcm[i] = i16((noise * 0.7 + low_freq * 0.3) * env * attack * 24000.0)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_powerup_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_dur := 45
	num_samples := (sample_rate * note_dur * notes.len) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	attack_samples := sample_rate * 2 / 1000

	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-14.0 * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
			pcm[sample_idx] = i16(harm * env * attack * 20000.0)
		}
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_hurt_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 280.0 - 180.0 * (f64(i) / f64(num_samples))
		env := math.exp(-12.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.4 * math.sin(2.0 * math.pi * 15.0 * t)
		pcm[i] = i16(harm * env * attack * 20000.0)
	}
	sm.play_pcm(pcm)
}
