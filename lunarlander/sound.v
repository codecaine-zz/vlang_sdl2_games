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

fn (sm &SoundManager) play_thrust_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 70
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		low_hum := math.sin(2.0 * math.pi * 90.0 * t)
		pcm[i] = i16((noise * 0.7 + low_hum * 0.3) * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_rcs_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		pcm[i] = i16(noise * 10000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_touchdown_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 350
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note := int(t * 12.0)
		freq := 300.0 + f64(note) * 80.0
		sine := math.sin(2.0 * math.pi * freq * t)
		pcm[i] = i16(sine * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_crash_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		env := math.exp(-8.0 * t)
		pcm[i] = i16(noise * env * 18000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}
