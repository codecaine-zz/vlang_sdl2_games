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
		sdl.pause_audio_device(dev_id, 0) // 0 = unpause / start audio thread
	}

	return SoundManager{
		dev:           dev_id
		sound_enabled: dev_id != 0
	}
}

fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if sm.dev != 0 {
		if mutable_sm.sound_enabled {
			sdl.pause_audio_device(sm.dev, 0) // 0 = unpause
			sm.play_gem_pickup()               // Play feedback chime when enabled
		} else {
			sdl.clear_queued_audio(sm.dev)
			sdl.pause_audio_device(sm.dev, 1) // 1 = pause
		}
	}
	return mutable_sm.sound_enabled
}

fn (sm &SoundManager) play_gem_pickup() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 90
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	// Arpeggiated high chime (E5 -> B5 -> E6)
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		mut freq := 659.25 // E5
		if i > num_samples / 3 {
			freq = 987.77 // B5
		}
		if i > (num_samples * 2) / 3 {
			freq = 1318.51 // E6
		}
		sine := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-15.0 * t)
		pcm[i] = i16(sine * env * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_boost_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 200
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	// Rising turbine roar
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 200.0 + 800.0 * (f64(i) / f64(num_samples))
		sine := math.sin(2.0 * math.pi * freq * t)
		noise := (rand.f64() * 2.0 - 1.0) * 0.3
		env := math.sin(math.pi * (f64(i) / f64(num_samples)))
		pcm[i] = i16((sine * 0.7 + noise) * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_jump_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	// Resonant pitch sweep up
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 150.0 + 600.0 * (f64(i) / f64(num_samples))
		sine := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-8.0 * t)
		pcm[i] = i16(sine * env * 10000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_crash_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	// Explosive noise + sub bass drop
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		sub_freq := 80.0 * math.exp(-10.0 * t)
		sub := math.sin(2.0 * math.pi * sub_freq * t)
		env := math.exp(-7.0 * t)
		sig := (noise * 0.6 + sub * 0.5) * env
		pcm[i] = i16(sig * 18000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_near_miss() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 100
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	// Dual-tone combo ping (A5 + C#6)
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		s1 := math.sin(2.0 * math.pi * 880.0 * t)
		s2 := math.sin(2.0 * math.pi * 1108.73 * t)
		env := math.exp(-20.0 * t)
		pcm[i] = i16((s1 + s2) * 0.5 * env * 11000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_steer_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	// Crisp high-tech thruster blip (400 Hz -> 800 Hz sweep)
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0 + 400.0 * (f64(i) / f64(num_samples))
		sine := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-25.0 * t)
		pcm[i] = i16(sine * env * 9000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_shield_hit() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 150
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	// Metallic forcefield deflection buzz
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 300.0 - 150.0 * (f64(i) / f64(num_samples))
		sine := math.sin(2.0 * math.pi * freq * t)
		noise := (rand.f64() * 2.0 - 1.0) * 0.4
		env := math.exp(-12.0 * t)
		pcm[i] = i16((sine * 0.6 + noise * 0.4) * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}
