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

fn (sm &SoundManager) play_pcm(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

fn (sm &SoundManager) play_click_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 30
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 850.0 - (500.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-55.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)
		val := harm * env * attack * 14000.0
		pcm[i] = i16(val)
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_flag_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 65
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 600.0 + (400.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-32.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
		val := harm * env * attack * 16000.0
		pcm[i] = i16(val)
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_unflag_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 750.0 - (350.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-35.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)
		val := harm * env * attack * 14000.0
		pcm[i] = i16(val)
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_cascade_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 160
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 350.0 + 700.0 * math.sin(t * 30.0)
		env := math.exp(-14.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := (math.sin(2.0 * math.pi * freq * t) * 0.7 + math.sin(4.0 * math.pi * freq * t) * 0.3)
		val := harm * env * attack * 16000.0
		pcm[i] = i16(val)
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_explode_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 500
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		sub_freq := 130.0 - (100.0 * (f64(i) / f64(num_samples)))
		sub := math.sin(2.0 * math.pi * sub_freq * t)
		env := math.exp(-6.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		val := (noise * 0.65 + sub * 0.35) * env * attack * 24000.0
		pcm[i] = i16(val)
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
	total_samples := (sample_rate * (note_dur_ms * 4 + 180)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_dur := if n_idx == notes.len - 1 { 180 } else { note_dur_ms }
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
