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

pub fn (sm &SoundManager) play_engine_sound(speed_ratio f64) {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.08
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	base_freq := 80.0 + speed_ratio * 320.0 // Engine rev pitch sweep
	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		saw := (t * base_freq) - math.floor(t * base_freq)
		sample := saw * 2.0 - 1.0
		pcm << i16(sample * 8000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_skid_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.12
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		noise := (rand.f64() * 2.0 - 1.0)
		high_freq := math.sin(2.0 * math.pi * 1800.0 * t)
		pcm << i16((noise * 0.7 + high_freq * 0.3) * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_crash_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.25
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		noise := (rand.f64() * 2.0 - 1.0)
		env := math.exp(-t * 12.0)
		pcm << i16(noise * env * 18000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_boost_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.3
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := 300.0 + t * 1200.0
		sample := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-t * 5.0)
		pcm << i16(sample * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_gate_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	duration := 0.15
	sample_rate := 44100
	num_samples := int(duration * sample_rate)
	mut pcm := []i16{cap: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / sample_rate
		freq := 880.0
		sample := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-t * 15.0)
		pcm << i16(sample * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}
