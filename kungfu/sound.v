module main

import math
import rand
import sdl

pub struct SoundManager {
pub mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	bgm_step      int
	bgm_phase     f64
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

// Procedural Kung-Fu Master Pagoda Combat BGM
pub fn (sm &SoundManager) update_bgm(dt f64, is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 || !is_active {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev)
	if queued > u32(44100 * 2 / 5) {
		return
	}

	mut mutable_sm := unsafe { &SoundManager(sm) }

	sample_rate := 44100
	step_duration := 0.12 // ~125 BPM
	samples_per_step := int(f64(sample_rate) * step_duration)
	mut pcm := []i16{len: samples_per_step}

	// Pentatonic martial arts driving melody (D minor / G pentatonic)
	lead_melody := [
		293.66, 0.0, 329.63, 392.00, 440.00, 392.00, 329.63, 293.66,
		261.63, 0.0, 293.66, 329.63, 392.00, 440.00, 523.25, 0.0,
		587.33, 0.0, 523.25, 440.00, 392.00, 440.00, 523.25, 587.33,
		659.25, 0.0, 587.33, 523.25, 440.00, 392.00, 293.66, 0.0,
	]
	// Driving martial bassline
	bass_notes := [
		146.83, 146.83, 220.00, 146.83, 196.00, 146.83, 220.00, 146.83,
		130.81, 130.81, 196.00, 130.81, 146.83, 146.83, 220.00, 146.83,
		146.83, 146.83, 220.00, 146.83, 174.61, 174.61, 220.00, 174.61,
		146.83, 146.83, 220.00, 146.83, 130.81, 130.81, 146.83, 146.83,
	]

	step := mutable_sm.bgm_step % lead_melody.len
	lead_freq := lead_melody[step]
	bass_freq := bass_notes[step]

	for i in 0 .. samples_per_step {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-7.0 * (f64(i) / f64(samples_per_step)))

		mut lead := 0.0
		if lead_freq > 0.0 {
			lead = if math.sin(2.0 * math.pi * lead_freq * (t + mutable_sm.bgm_phase)) > 0.0 { 1.0 } else { -1.0 }
		}

		bass := math.sin(2.0 * math.pi * bass_freq * (t + mutable_sm.bgm_phase))

		// Percussion snare / woodblock
		mut drum := 0.0
		if step % 2 == 1 && i < samples_per_step / 3 {
			noise := f64((i * 1103515245 + 12345) % 65536) / 32768.0 - 1.0
			drum = noise * math.exp(-30.0 * t)
		}

		sample_val := (lead * 0.26 * env + bass * 0.24 + drum * 0.16) * 11000.0
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, sample_val)))
	}

	mutable_sm.bgm_phase += step_duration
	mutable_sm.bgm_step++
	sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
}

pub fn (sm &SoundManager) play_punch() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq := 680.0 - 450.0 * progress
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - progress
		pcm[i] = i16(sq * env * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_kick() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 95
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq := 820.0 - 580.0 * progress
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - progress
		pcm[i] = i16(sq * env * 13500.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_hit() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 110
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		freq := 320.0 - 240.0 * progress
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-12.0 * t)
		pcm[i] = i16((noise * 0.6 + sq * 0.4) * env * 17000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_deflect() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		s1 := math.sin(2.0 * math.pi * 2637.0 * t) // E7
		s2 := math.sin(2.0 * math.pi * 3520.0 * t) // A7
		env := math.exp(-20.0 * t)
		pcm[i] = i16((s1 * 0.6 + s2 * 0.4) * env * 18000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_grab() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 100
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq := 400.0 + 350.0 * math.sin(progress * math.pi * 6.0)
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - progress
		pcm[i] = i16(sq * env * 11000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_pot_smash() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 130
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		env := math.exp(-14.0 * t)
		pcm[i] = i16(noise * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_floor_clear() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 700
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51] // C5, E5, G5, C6, E6
	note_len := num_samples / notes.len

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(math.min(f64(i / note_len), f64(notes.len - 1)))
		freq := notes[note_idx]
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - (f64(i % note_len) / f64(note_len)) * 0.4
		pcm[i] = i16(sq * env * 15000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_die() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 550
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq := 480.0 - 360.0 * progress
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-4.5 * progress)
		pcm[i] = i16(sq * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}
