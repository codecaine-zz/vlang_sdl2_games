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

fn (sm &SoundManager) play_rain_patter(intensity f64) {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		// Filtered white noise with random droplet pop spikes
		noise := (rand.f64() * 2.0 - 1.0) * 0.4
		drop_pop := if rand.f64() < 0.05 * intensity { (rand.f64() * 2.0 - 1.0) * 0.8 } else { 0.0 }
		env := math.sin(math.pi * (f64(i) / f64(num_samples)))
		sig := (noise + drop_pop) * env * intensity
		pcm[i] = i16(sig * 6000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_thunder_rumble() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		sub_freq := 45.0 + math.sin(t * 15.0) * 20.0
		sub := math.sin(2.0 * math.pi * sub_freq * t)
		rumble_noise := (rand.f64() * 2.0 - 1.0) * 0.6
		env := math.exp(-6.0 * t) * (1.0 - math.exp(-30.0 * t))
		sig := (sub * 0.7 + rumble_noise * 0.3) * env
		pcm[i] = i16(sig * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_splash_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1800.0 - 1200.0 * (f64(i) / f64(num_samples))
		sine := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-35.0 * t)
		pcm[i] = i16(sine * env * 8000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_lightning_strike() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 250
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		crack := (rand.f64() * 2.0 - 1.0)
		bass := math.sin(2.0 * math.pi * 60.0 * t)
		env := math.exp(-12.0 * t)
		pcm[i] = i16((crack * 0.8 + bass * 0.5) * env * 22000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}
