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

fn (sm &SoundManager) play_slide_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 450.0 - (280.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-40.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.2 * math.sin(4.0 * math.pi * freq * t)
		val := harm * env * attack * 12000.0
		pcm[i] = i16(val)
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_merge_sound(val int) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 130
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	// Pentatonic scale based on tile power of 2
	mut power := 0
	mut temp := val
	for temp > 2 {
		temp /= 2
		power++
	}

	scale_notes := [
		261.63, // 4: C4
		293.66, // 8: D4
		329.63, // 16: E4
		392.00, // 32: G4
		440.00, // 64: A4
		523.25, // 128: C5
		587.33, // 256: D5
		659.25, // 512: E5
		783.99, // 1024: G5
		1046.50, // 2048: C6
		1174.66, // 4096: D6
		1318.51, // 8192: E6
	]
	idx := if power < scale_notes.len { power } else { scale_notes.len - 1 }
	freq := scale_notes[idx]

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-18.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t) + 0.15 * math.sin(6.0 * math.pi * freq * t)
		val_f := harm * env * attack * 18000.0
		pcm[i] = i16(val_f)
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_win_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51] // C5, E5, G5, C6, E6
	note_dur_ms := 80
	total_samples := (sample_rate * (note_dur_ms * 4 + 200)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_dur := if n_idx == notes.len - 1 { 200 } else { note_dur_ms }
		note_samples := (sample_rate * note_dur) / 1000
		attack_samples := sample_rate * 2 / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			decay := if n_idx == notes.len - 1 { -6.0 } else { -10.0 }
			env := math.exp(decay * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
			val := harm * env * attack * 22000.0
			pcm[start_sample + i] = i16(val)
		}
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_game_over_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	notes := [330.0, 311.13, 293.66, 261.63]
	note_dur_ms := 90
	total_samples := (sample_rate * note_dur_ms * notes.len) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_samples := (sample_rate * note_dur_ms) / 1000
		attack_samples := sample_rate * 2 / 1000
		for i in 0 .. note_samples {
			t := f64(i) / f64(sample_rate)
			env := math.exp(-8.0 * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			val := math.sin(2.0 * math.pi * freq * t) * env * attack * 16000.0
			pcm[start_sample + i] = i16(val)
		}
	}

	sm.play_pcm(pcm)
}
