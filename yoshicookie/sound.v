module main

import math
import sdl

pub enum CookieBgmType {
	type_a
	type_b
	off
}

pub struct SoundManager {
pub mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	bgm_type      CookieBgmType = .type_a
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

pub fn (sm &SoundManager) cycle_bgm() CookieBgmType {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.bgm_type = match mutable_sm.bgm_type {
		.type_a { CookieBgmType.type_b }
		.type_b { CookieBgmType.off }
		.off { CookieBgmType.type_a }
	}
	if mutable_sm.bgm_type == .off && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return mutable_sm.bgm_type
}

// Procedural Yoshi's Cookie Type A & Type B Soundtrack Synthesizers
pub fn (sm &SoundManager) update_bgm(dt f64, is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 || !is_active || sm.bgm_type == .off {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev)
	if queued > u32(44100 * 2 / 5) {
		return
	}

	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100

	if sm.bgm_type == .type_b {
		// 64-step Yoshi's Cookie Music B Theme (Fast Syncopated Allegro Swing)
		step_duration := 0.108 // ~138 BPM energetic pastry bounce
		samples_per_step := int(f64(sample_rate) * step_duration)
		mut pcm := []i16{len: samples_per_step}

		b_lead := [
			// Phrase 1 (Fast galloping hook)
			523.25, 0.0, 523.25, 659.25, 783.99, 0.0, 659.25, 523.25,
			587.33, 0.0, 587.33, 698.46, 880.00, 0.0, 783.99, 587.33,
			659.25, 0.0, 659.25, 783.99, 1046.50, 0.0, 880.00, 659.25,
			783.99, 659.25, 587.33, 523.25, 493.88, 523.25, 587.33, 0.0,
			// Phrase 2 (Ascending cascade)
			659.25, 783.99, 880.00, 1046.50, 1174.66, 1046.50, 880.00, 783.99,
			698.46, 880.00, 1046.50, 1174.66, 1318.51, 1174.66, 1046.50, 880.00,
			783.99, 1046.50, 1318.51, 1567.98, 1396.91, 1174.66, 1046.50, 880.00,
			783.99, 659.25, 587.33, 523.25, 587.33, 659.25, 523.25, 0.0,
		]

		b_bass := [
			130.81, 261.63, 196.00, 261.63, 130.81, 261.63, 196.00, 261.63,
			146.83, 293.66, 220.00, 293.66, 146.83, 293.66, 220.00, 293.66,
			164.81, 329.63, 246.94, 329.63, 164.81, 329.63, 246.94, 329.63,
			174.61, 349.23, 196.00, 392.00, 130.81, 261.63, 196.00, 130.81,
			164.81, 329.63, 246.94, 329.63, 164.81, 329.63, 246.94, 329.63,
			174.61, 349.23, 261.63, 349.23, 174.61, 349.23, 261.63, 349.23,
			196.00, 392.00, 293.66, 392.00, 196.00, 392.00, 293.66, 392.00,
			130.81, 196.00, 261.63, 196.00, 130.81, 196.00, 261.63, 130.81,
		]

		step := mutable_sm.bgm_step % b_lead.len
		lead_freq := b_lead[step]
		bass_freq := b_bass[step]

		for i in 0 .. samples_per_step {
			t := f64(i) / f64(sample_rate)
			progress := f64(i) / f64(samples_per_step)

			mut lead_val := 0.0
			if lead_freq > 0.0 {
				sq := if math.sin(2.0 * math.pi * lead_freq * t) > 0.0 { 1.0 } else { -1.0 }
				env := math.exp(-8.0 * progress)
				lead_val = sq * env * 8500.0
			}

			mut bass_val := 0.0
			if bass_freq > 0.0 {
				tri := 2.0 * math.abs(2.0 * (t * bass_freq - math.floor(t * bass_freq + 0.5))) - 1.0
				b_env := math.exp(-5.0 * progress)
				bass_val = tri * b_env * 9000.0
			}

			mut drum_val := 0.0
			if step % 2 == 1 && progress < 0.20 {
				noise := (f64((i * 1103515245 + 12345) & 0x7FFFFFFF) / 2147483648.0) * 2.0 - 1.0
				drum_val = noise * (1.0 - progress / 0.20) * 2500.0
			}

			sample := lead_val + bass_val + drum_val
			pcm[i] = i16(math.max(-32000.0, math.min(32000.0, sample)))
		}

		sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
		mutable_sm.bgm_step++
		return
	}

	// Type A Bakery Ragtime
	step_duration := 0.125 // ~120 BPM bouncy swing ragtime
	samples_per_step := int(f64(sample_rate) * step_duration)
	mut pcm := []i16{len: samples_per_step}

	// 64-step Yoshi's Cookie Music A Theme (G Major / C Major bouncy waltz-ragtime)
	lead_melody := [
		// Bar 1-2
		392.00, 493.88, 587.33, 783.99, 659.25, 587.33, 493.88, 392.00,
		440.00, 523.25, 659.25, 880.00, 783.99, 659.25, 523.25, 440.00,
		// Bar 3-4
		587.33, 659.25, 783.99, 987.77, 880.00, 783.99, 659.25, 587.33,
		783.99, 659.25, 587.33, 493.88, 392.00, 0.0, 392.00, 0.0,
		// Bar 5-6 (Pastry bounce)
		523.25, 659.25, 783.99, 1046.50, 987.77, 880.00, 783.99, 659.25,
		493.88, 587.33, 739.99, 987.77, 880.00, 739.99, 587.33, 493.88,
		// Bar 7-8 (Resolution)
		440.00, 523.25, 659.25, 880.00, 783.99, 659.25, 587.33, 523.25,
		392.00, 493.88, 587.33, 783.99, 392.00, 0.0, 392.00, 0.0,
	]

	harmony_melody := [
		261.63, 329.63, 392.00, 523.25, 440.00, 392.00, 329.63, 261.63,
		293.66, 349.23, 440.00, 587.33, 523.25, 440.00, 349.23, 293.66,
		392.00, 440.00, 523.25, 659.25, 587.33, 523.25, 440.00, 392.00,
		493.88, 440.00, 392.00, 329.63, 261.63, 0.0, 261.63, 0.0,
		329.63, 392.00, 523.25, 659.25, 587.33, 523.25, 493.88, 392.00,
		293.66, 369.99, 440.00, 587.33, 523.25, 440.00, 369.99, 293.66,
		261.63, 329.63, 392.00, 523.25, 440.00, 392.00, 349.23, 293.66,
		261.63, 329.63, 392.00, 523.25, 261.63, 0.0, 261.63, 0.0,
	]

	bass_notes := [
		196.00, 392.00, 293.66, 392.00, 220.00, 440.00, 293.66, 440.00,
		220.00, 440.00, 261.63, 440.00, 196.00, 392.00, 293.66, 392.00,
		293.66, 587.33, 369.99, 587.33, 329.63, 659.25, 293.66, 587.33,
		196.00, 392.00, 293.66, 392.00, 196.00, 196.00, 196.00, 0.0,
		261.63, 523.25, 329.63, 523.25, 220.00, 440.00, 261.63, 440.00,
		246.94, 493.88, 293.66, 493.88, 196.00, 392.00, 246.94, 392.00,
		220.00, 440.00, 261.63, 440.00, 196.00, 392.00, 246.94, 392.00,
		196.00, 392.00, 293.66, 392.00, 196.00, 196.00, 196.00, 0.0,
	]

	step := mutable_sm.bgm_step % lead_melody.len
	lead_freq := lead_melody[step]
	harm_freq := harmony_melody[step]
	bass_freq := bass_notes[step]

	for i in 0 .. samples_per_step {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-7.5 * (f64(i) / f64(samples_per_step)))

		// 1. Lead pulse wave (warm bell tone)
		mut lead := 0.0
		if lead_freq > 0.0 {
			vib := 1.0 + 0.012 * math.sin(2.0 * math.pi * 5.5 * (t + mutable_sm.bgm_phase))
			lead = if math.sin(2.0 * math.pi * lead_freq * vib * (t + mutable_sm.bgm_phase)) > 0.3 { 1.0 } else { -1.0 }
		}

		// 2. Harmony pulse wave
		mut harm := 0.0
		if harm_freq > 0.0 {
			harm = if math.sin(2.0 * math.pi * harm_freq * (t + mutable_sm.bgm_phase)) > 0.0 { 1.0 } else { -1.0 }
		}

		// 3. Bouncy walking bass
		bass := math.sin(2.0 * math.pi * bass_freq * (t + mutable_sm.bgm_phase)) * math.exp(-3.5 * (f64(i) / f64(samples_per_step)))

		// 4. Pastry Kitchen Percussion
		mut drum := 0.0
		if step % 4 == 2 && i < samples_per_step / 3 {
			// Snare click
			noise := f64((i * 1103515245 + 12345) % 65536) / 32768.0 - 1.0
			drum = noise * math.exp(-26.0 * t) * 1.4
		} else if step % 4 == 0 && i < samples_per_step / 4 {
			// Bass drum thump
			b_freq := 110.0 - 70.0 * (f64(i) / f64(samples_per_step / 4))
			drum = math.sin(2.0 * math.pi * b_freq * t) * math.exp(-20.0 * t) * 1.3
		} else if step % 2 == 1 && i < samples_per_step / 5 {
			// Sugar sprinkle hi-hat
			noise := f64((i * 1103515245 + 12345) % 65536) / 32768.0 - 1.0
			drum = noise * math.exp(-42.0 * t) * 0.6
		}

		sample_val := (lead * 0.28 * env + harm * 0.16 * env + bass * 0.26 + drum * 0.20) * 13000.0
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, sample_val)))
	}

	mutable_sm.bgm_phase += step_duration
	mutable_sm.bgm_step++
	sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
}

pub fn (sm &SoundManager) play_shift() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 45
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq := 480.0 + 260.0 * progress
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - progress
		pcm[i] = i16(sq * env * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_clear() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq := if progress < 0.33 { 659.25 } else if progress < 0.66 { 783.99 } else { 1046.50 }
		sq := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-8.0 * t)
		pcm[i] = i16(sq * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_combo(chain int) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 240
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	base_freq := 523.25 * math.pow(1.2, f64(chain))
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq := base_freq * (1.0 + progress * 0.8)
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		bell := math.sin(2.0 * math.pi * freq * 2.0 * t)
		env := math.exp(-7.0 * t)
		pcm[i] = i16((sq * 0.6 + bell * 0.4) * env * 16500.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_conveyor_tick() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 55
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 320.0
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-25.0 * t)
		pcm[i] = i16(sq * env * 11000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_stage_clear() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 480
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		sub_idx := int(t / (0.48 / f64(notes.len)))
		freq := if sub_idx < notes.len { notes[sub_idx] } else { notes.last() }
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		harm := math.sin(2.0 * math.pi * freq * 1.5 * t)
		env := math.exp(-3.5 * t)
		pcm[i] = i16((sq * 0.7 + harm * 0.3) * env * 17000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_game_over() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 550
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [523.25, 493.88, 440.00, 392.00, 349.23, 261.63]
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		sub_idx := int(t / (0.55 / f64(notes.len)))
		freq := if sub_idx < notes.len { notes[sub_idx] } else { notes.last() }
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-3.0 * t)
		pcm[i] = i16(sq * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_stash() {
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
		freq := 523.25 + 400.0 * progress
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - progress
		pcm[i] = i16(sq * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_speed_push() {
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
		freq := 300.0 - 150.0 * progress
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-6.0 * progress)
		pcm[i] = i16(sq * env * 18000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}
