module main

import math
import rand
import sdl

pub struct SoundManager {
pub mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	roll_timer    f32
}

pub fn new_sound_manager() SoundManager {
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

pub fn (sm &SoundManager) play_bounce(intensity f32) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	clamped_int := math.max(0.2, math.min(1.0, f64(intensity)))
	sample_rate := 44100
	duration_ms := int(40.0 + clamped_int * 30.0)
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	base_freq := 300.0 + clamped_int * 200.0
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := base_freq * (1.0 - t * 4.0)
		env := math.exp(-25.0 * t) * clamped_int
		// Triangle / Square hybrid sound
		tri := 2.0 * math.abs(2.0 * (t * freq - math.floor(t * freq + 0.5))) - 1.0
		pcm[i] = i16(tri * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_shatter() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		sq := if math.sin(2.0 * math.pi * (400.0 * (1.0 - t * 2.0)) * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-10.0 * t)
		pcm[i] = i16((noise * 0.7 + sq * 0.3) * env * 22000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_respawn() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 250.0 + 750.0 * (f64(i) / f64(num_samples))
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - (t / (f64(duration_ms) / 1000.0))
		pcm[i] = i16(sq * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_muncher_chomp() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 200
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 180.0 * math.exp(-8.0 * t)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-12.0 * t)
		pcm[i] = i16((noise * 0.4 + sq * 0.6) * env * 20000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_boost() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0 + 800.0 * (f64(i) / f64(num_samples))
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-8.0 * t)
		pcm[i] = i16(sq * env * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_spring() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 200.0 + 600.0 * math.sin(2.0 * math.pi * 15.0 * t)
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-7.0 * t)
		pcm[i] = i16(sq * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_tube() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 250
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 600.0 + 400.0 * math.sin(2.0 * math.pi * 30.0 * t)
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-6.0 * t)
		pcm[i] = i16(sq * env * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_warning() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 100
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 880.0
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-12.0 * t)
		pcm[i] = i16(sq * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_goal() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 600
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	// Arpeggio: C4, E4, G4, C5
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_len := num_samples / notes.len

	for i in 0 .. num_samples {
		note_idx := math.min(notes.len - 1, i / note_len)
		freq := notes[note_idx]
		t := f64(i) / f64(sample_rate)
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		t_in_note := f64(i % note_len) / f64(sample_rate)
		env := math.exp(-6.0 * t_in_note)
		pcm[i] = i16(sq * env * 15000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_game_over() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 700
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [440.0, 415.3, 392.0, 349.23]
	note_len := num_samples / notes.len

	for i in 0 .. num_samples {
		note_idx := math.min(notes.len - 1, i / note_len)
		freq := notes[note_idx]
		t := f64(i) / f64(sample_rate)
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		t_in_note := f64(i % note_len) / f64(sample_rate)
		env := math.exp(-5.0 * t_in_note)
		pcm[i] = i16(sq * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_rolling(speed f32, dt f32) {
	if !sm.sound_enabled || sm.dev == 0 || speed < 0.2 {
		return
	}
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.roll_timer += dt
	if mutable_sm.roll_timer < 0.08 {
		return
	}
	mutable_sm.roll_timer = 0

	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	freq := 60.0 + f64(math.min(10.0, speed)) * 30.0
	vol := f64(math.min(1.0, speed / 6.0)) * 6000.0

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		tri := 2.0 * math.abs(2.0 * (t * freq - math.floor(t * freq + 0.5))) - 1.0
		pcm[i] = i16((tri * 0.6 + noise * 0.4) * vol)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}
