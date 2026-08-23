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

pub fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return mutable_sm.sound_enabled
}

pub fn (sm &SoundManager) clear_audio() {
	if sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
}

pub fn (sm &SoundManager) play_jump_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.15
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := 250.0 + t * 900.0 // Ascending sweep
		sample := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-t * 12.0)
		pcm << i16(sample * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_land_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.1
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := 120.0 - t * 400.0
		if freq < 40 { break }
		sample := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-t * 20.0)
		pcm << i16(sample * env * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_coin_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.2
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := if t < 0.1 { 987.77 } else { 1318.51 } // B5 -> E6 chime
		sample := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-t * 10.0)
		pcm << i16(sample * env * 15000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_dash_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.18
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		noise := rand.f64() * 2.0 - 1.0
		env := math.sin(t / duration * math.pi)
		pcm << i16(noise * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_fire_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.15
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := 600.0 - t * 2500.0
		sample := if freq > 50 { math.sin(2.0 * math.pi * freq * t) } else { 0.0 }
		noise := (rand.f64() * 2.0 - 1.0) * 0.4
		env := math.exp(-t * 15.0)
		pcm << i16((sample + noise) * env * 15000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_hit_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.25
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := 180.0 - t * 400.0
		sample := if freq > 30 { math.sin(2.0 * math.pi * freq * t) } else { 0.0 }
		noise := (rand.f64() * 2.0 - 1.0) * 0.6
		env := math.exp(-t * 10.0)
		pcm << i16((sample + noise) * env * 18000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_kill_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.15
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := 400.0 + t * 800.0
		sample := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-t * 18.0)
		pcm << i16(sample * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_win_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.6
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50] // C5, E5, G5, C6
	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		idx := int(t / 0.15) % notes.len
		freq := notes[idx]
		sample := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-(t - f64(idx) * 0.15) * 6.0)
		pcm << i16(sample * env * 15000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}
