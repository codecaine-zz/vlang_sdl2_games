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

pub fn (sm &SoundManager) play_thud_sound(intensity f64) {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := math.min(0.2, 0.05 + intensity * 0.05)
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	base_freq := math.max(40.0, 150.0 - intensity * 30.0)
	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := base_freq * math.exp(-t * 25.0)
		sample := math.sin(2.0 * math.pi * freq * t)
		noise := (rand.f64() * 2.0 - 1.0) * 0.3 * math.exp(-t * 30.0)
		env := math.exp(-t * 20.0)
		vol := math.min(24000.0, 10000.0 + intensity * 7000.0)
		pcm << i16((sample + noise) * env * vol)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_crunch_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.15
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		noise := (rand.f64() * 2.0 - 1.0)
		crack := if (i % 250) < 40 { 1.5 } else { 0.5 }
		env := math.exp(-t * 22.0)
		pcm << i16(noise * crack * env * 18000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_explosion_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.4
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		sub_freq := 60.0 * math.exp(-t * 6.0)
		sub := math.sin(2.0 * math.pi * sub_freq * t)
		noise := (rand.f64() * 2.0 - 1.0)
		env := math.exp(-t * 7.0)
		pcm << i16((sub * 0.6 + noise * 0.4) * env * 24000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_gravgun_zap() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.18
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := 1200.0 - t * 4000.0
		sample := if freq > 80 { math.sin(2.0 * math.pi * freq * t) } else { 0.0 }
		env := math.exp(-t * 15.0)
		pcm << i16(sample * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_boing_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.25
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := 150.0 + math.sin(t * 40.0) * 120.0
		sample := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-t * 8.0)
		pcm << i16(sample * env * 18000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_bumper_chime() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.2
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := 880.0 // A5 note
		sample := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-t * 12.0)
		pcm << i16(sample * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_tether_snap() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.1
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := 400.0 + t * 1500.0
		sample := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-t * 25.0)
		pcm << i16(sample * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}
