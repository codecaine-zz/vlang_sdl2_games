module main

import math
import sdl

pub struct SoundManager {
pub mut:
	dev_id        u32
	sound_enabled bool = true
	sample_pos    f64
	cur_world     int = 1
	sfx_buffer    []i16
	sfx_read_pos  int
}

pub fn new_sound_manager() SoundManager {
	mut sm := SoundManager{}
	desired := sdl.AudioSpec{
		freq:     44100
		format:   sdl.AudioFormat(sdl.audio_s16sys)
		channels: 1
		samples:  1024
		callback: unsafe { nil }
	}
	mut obtained := sdl.AudioSpec{}
	dev := sdl.open_audio_device(unsafe { nil }, 0, &desired, &obtained, 0)
	if dev > 0 {
		sm.dev_id = dev
		sdl.pause_audio_device(dev, 0)
	}
	return sm
}

pub fn (mut sm SoundManager) toggle_sound() {
	sm.sound_enabled = !sm.sound_enabled
	if !sm.sound_enabled && sm.dev_id > 0 {
		sdl.clear_queued_audio(sm.dev_id)
		sm.sfx_buffer.clear()
		sm.sfx_read_pos = 0
	}
}

pub fn (mut sm SoundManager) set_world(w int) {
	sm.cur_world = w
	sm.sample_pos = 0.0
}

// Push SFX into stream
fn (mut sm SoundManager) play_sfx(samples []i16) {
	if !sm.sound_enabled || sm.dev_id == 0 { return }
	sm.sfx_buffer.clear()
	sm.sfx_read_pos = 0
	for s in samples {
		sm.sfx_buffer << s
	}
}

// Background Music Stream Generator
pub fn (mut sm SoundManager) update_audio_stream(world_num int, is_boss bool, is_playing bool) {
	if !sm.sound_enabled || sm.dev_id == 0 { return }
	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued > u32(44100 * 2 / 5) {
		return
	}

	sample_rate := 44100.0
	samples_to_gen := 44100 / 12 // ~83ms chunks
	mut samples := []i16{len: samples_to_gen}

	for i in 0 .. samples_to_gen {
		total_sample := int(sm.sample_pos) + i
		t := f64(total_sample) / sample_rate

		mut bgm_val := 0.0
		if is_playing {
			bgm_val = sm.synthesize_world_bgm(world_num, is_boss, t, total_sample)
		} else {
			bgm_val = sm.synthesize_title_bgm(t, total_sample)
		}

		// Fast O(1) SFX mixing
		mut sfx_val := 0.0
		if sm.sfx_read_pos < sm.sfx_buffer.len {
			sfx_val = f64(sm.sfx_buffer[sm.sfx_read_pos])
			sm.sfx_read_pos++
			if sm.sfx_read_pos >= sm.sfx_buffer.len {
				sm.sfx_buffer.clear()
				sm.sfx_read_pos = 0
			}
		}

		mixed := bgm_val * 0.45 + sfx_val * 0.85
		clamped := math.max(-32000.0, math.min(32000.0, mixed))
		samples[i] = i16(clamped)
	}

	sm.sample_pos += f64(samples_to_gen)
	sdl.queue_audio(sm.dev_id, unsafe { samples.data }, u32(samples_to_gen * 2))
}

// 1. Title Theme: Cosmic Odyssey (122 BPM)
fn (sm &SoundManager) synthesize_title_bgm(t f64, _total_sample int) f64 {
	step_time := 0.123
	step := int(t / step_time) % 32

	lead_notes := [
		329.63, 392.00, 493.88, 587.33, 659.25, 587.33, 493.88, 392.00, // Em
		261.63, 329.63, 392.00, 523.25, 587.33, 523.25, 392.00, 329.63, // C
		293.66, 369.99, 440.00, 587.33, 659.25, 587.33, 440.00, 369.99, // D
		246.94, 311.13, 369.99, 493.88, 587.33, 493.88, 369.99, 311.13  // B
	]
	bass_notes := [82.41, 65.41, 73.42, 61.74]

	freq := lead_notes[step]
	bass_freq := bass_notes[step / 8]

	local_t := math.fmod(t, step_time)
	env := math.pow(1.0 - (local_t / step_time), 1.5)

	lead := (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env
	bass := math.sin(2.0 * math.pi * bass_freq * t) * 0.8
	return (lead * 12000.0 + bass * 14000.0)
}

// 2. World-Specific Multi-Theme Synthesizers
fn (sm &SoundManager) synthesize_world_bgm(world_num int, is_boss bool, t f64, total_sample int) f64 {
	match world_num {
		1 {
			// World 1: Solar Plains - Upbeat Driving Synthwave (135 BPM, D Minor)
			step_time := 0.111
			step := int(t / step_time) % 32
			lead_notes := [
				293.66, 349.23, 440.00, 523.25, 587.33, 523.25, 440.00, 349.23, // Dm
				261.63, 329.63, 392.00, 523.25, 659.25, 523.25, 392.00, 329.63, // C
				233.08, 293.66, 349.23, 466.16, 587.33, 466.16, 349.23, 293.66, // Bb
				220.00, 277.18, 329.63, 440.00, 554.37, 440.00, 329.63, 277.18  // A
			]
			bass_notes := [73.42, 65.41, 58.27, 55.00] // D1, C1, Bb0, A0
			freq := if is_boss { lead_notes[step] * 1.5 } else { lead_notes[step] }
			bass_freq := bass_notes[step / 8]

			local_t := math.fmod(t, step_time)
			env := math.pow(1.0 - (local_t / step_time), 1.3)
			noise := if step % 2 == 1 { (f64((total_sample * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * env * 0.25 } else { 0.0 }

			lead := math.sin(2.0 * math.pi * freq * t) * env
			bass := (math.sin(2.0 * math.pi * bass_freq * t) + 0.3 * math.sin(4.0 * math.pi * bass_freq * t)) * 0.9
			return (lead * 11000.0 + bass * 13000.0 + noise * 10000.0)
		}
		2 {
			// World 2: Crystal Caverns - Mystical Prismatic Cosmic Arpeggios (128 BPM, A Minor)
			step_time := 0.117
			step := int(t / step_time) % 32
			lead_notes := [
				440.00, 523.25, 659.25, 880.00, 1046.50, 880.00, 659.25, 523.25, // Am
				349.23, 440.00, 523.25, 698.46, 880.00, 698.46, 523.25, 440.00,  // F
				392.00, 493.88, 587.33, 783.99, 987.77, 783.99, 587.33, 493.88,  // G
				329.63, 415.30, 493.88, 659.25, 830.61, 659.25, 493.88, 415.30  // E7
			]
			bass_notes := [55.00, 43.65, 49.00, 41.20]
			freq := lead_notes[step]
			bass_freq := bass_notes[step / 8]

			local_t := math.fmod(t, step_time)
			env := math.pow(1.0 - (local_t / step_time), 2.0)
			lead := (math.sin(2.0 * math.pi * freq * t) + 0.4 * math.sin(6.0 * math.pi * freq * t)) * env
			bass := math.sin(2.0 * math.pi * bass_freq * t) * 0.85
			return (lead * 12000.0 + bass * 14000.0)
		}
		3 {
			// World 3: Magma Wasteland - Heavy Industrial Driving Cyber Riffs (142 BPM, E Minor)
			step_time := 0.105
			step := int(t / step_time) % 32
			lead_notes := [
				164.81, 196.00, 220.00, 246.94, 329.63, 246.94, 220.00, 196.00, // Em
				174.61, 207.65, 233.08, 261.63, 349.23, 261.63, 233.08, 207.65, // F
				146.83, 174.61, 196.00, 220.00, 293.66, 220.00, 196.00, 174.61, // D
				130.81, 164.81, 196.00, 246.94, 261.63, 246.94, 196.00, 164.81  // C
			]
			bass_notes := [41.20, 43.65, 36.71, 32.70]
			freq := lead_notes[step]
			bass_freq := bass_notes[step / 8]

			local_t := math.fmod(t, step_time)
			env := math.pow(1.0 - (local_t / step_time), 1.1)
			noise := if step % 2 == 0 { (f64((total_sample * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * env * 0.35 } else { 0.0 }

			lead := (math.sin(2.0 * math.pi * freq * t) + 0.5 * math.sin(3.0 * math.pi * freq * t)) * env
			bass := (math.sin(2.0 * math.pi * bass_freq * t) + 0.4 * math.sin(2.0 * math.pi * (bass_freq * 1.5) * t)) * 0.95
			return (lead * 10000.0 + bass * 15000.0 + noise * 11000.0)
		}
		4 {
			// World 4: Cyber Matrix - 16th-Note Acid Techno Sequencer (148 BPM, C Minor)
			step_time := 0.101
			step := int(t / step_time) % 32
			lead_notes := [
				261.63, 311.13, 392.00, 466.16, 523.25, 466.16, 392.00, 311.13, // Cm
				233.08, 293.66, 349.23, 466.16, 587.33, 466.16, 349.23, 293.66, // Bb
				207.65, 261.63, 311.13, 415.30, 523.25, 415.30, 311.13, 261.63, // Ab
				196.00, 246.94, 293.66, 392.00, 493.88, 392.00, 293.66, 246.94  // G
			]
			bass_notes := [65.41, 58.27, 51.91, 49.00]
			freq := lead_notes[step]
			bass_freq := bass_notes[step / 8]

			local_t := math.fmod(t, step_time)
			env := math.pow(1.0 - (local_t / step_time), 1.6)

			lead := math.sin(2.0 * math.pi * freq * t + math.sin(2.0 * math.pi * 14.0 * t) * 1.5) * env
			bass := math.sin(2.0 * math.pi * bass_freq * t) * 0.9
			return (lead * 12000.0 + bass * 13500.0)
		}
		else {
			// World 5: Cosmic Abyss - Epic Boss Symphony (152 BPM, F# Minor)
			step_time := 0.098
			step := int(t / step_time) % 32
			lead_notes := [
				369.99, 440.00, 554.37, 739.99, 880.00, 739.99, 554.37, 440.00, // F#m
				293.66, 369.99, 440.00, 587.33, 739.99, 587.33, 440.00, 369.99, // D
				246.94, 293.66, 369.99, 493.88, 587.33, 493.88, 369.99, 293.66, // Bm
				277.18, 349.23, 415.30, 554.37, 698.46, 554.37, 415.30, 349.23  // C#7
			]
			bass_notes := [46.25, 36.71, 30.87, 34.65]
			freq := lead_notes[step]
			bass_freq := bass_notes[step / 8]

			local_t := math.fmod(t, step_time)
			env := math.pow(1.0 - (local_t / step_time), 1.2)
			noise := if step % 2 == 1 { (f64((total_sample * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * env * 0.3 } else { 0.0 }

			lead := (math.sin(2.0 * math.pi * freq * t) + 0.5 * math.sin(2.0 * math.pi * (freq * 2.0) * t)) * env
			bass := (math.sin(2.0 * math.pi * bass_freq * t) + 0.3 * math.sin(4.0 * math.pi * bass_freq * t)) * 0.95
			return (lead * 13000.0 + bass * 15000.0 + noise * 12000.0)
		}
	}
}

// SFX Synthesizers
pub fn (mut sm SoundManager) play_laser() {
	sample_rate := 44100
	duration := 0.09
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1300.0 - t * 7500.0
		env := math.pow(1.0 - (t / duration), 1.2)
		val := math.sin(2.0 * math.pi * math.max(100.0, freq) * t) * env * 22000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (mut sm SoundManager) play_jump() {
	sample_rate := 44100
	duration := 0.15
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 260.0 + t * 1500.0
		env := 1.0 - (t / duration)
		val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (mut sm SoundManager) play_boost() {
	sample_rate := 44100
	duration := 0.20
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 200.0 + t * 1000.0
		env := 1.0 - (t / duration)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * 0.4
		val := (math.sin(2.0 * math.pi * freq * t) * 0.7 + noise) * env * 24000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (mut sm SoundManager) play_explosion() {
	sample_rate := 44100
	duration := 0.28
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.pow(1.0 - (t / duration), 1.2)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0)
		sub := math.sin(2.0 * math.pi * 65.0 * t) * 0.5
		val := (noise * 0.75 + sub) * env * 26000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (mut sm SoundManager) play_powerup() {
	sample_rate := 44100
	duration := 0.26
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	notes := [587.33, 739.99, 880.00, 1174.66]
	note_len := duration / f64(notes.len)

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(t / note_len)
		cur_note := if note_idx < notes.len { notes[note_idx] } else { notes[notes.len - 1] }
		local_t := math.fmod(t, note_len)
		env := 1.0 - (local_t / note_len)
		val := math.sin(2.0 * math.pi * cur_note * t) * env * 19000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (mut sm SoundManager) play_dragon_roar() {
	sample_rate := 44100
	duration := 0.40
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		carrier := 95.0 + math.sin(2.0 * math.pi * 18.0 * t) * 45.0
		mod := math.sin(2.0 * math.pi * 8.0 * t) * 60.0
		env := math.pow(1.0 - (t / duration), 0.7)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * 0.35
		val := (math.sin(2.0 * math.pi * (carrier + mod) * t) + noise) * env * 25000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (mut sm SoundManager) play_victory() {
	sample_rate := 44100
	duration := 0.60
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	note_len := duration / f64(notes.len)

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(t / note_len)
		cur_note := if note_idx < notes.len { notes[note_idx] } else { notes[notes.len - 1] }
		local_t := math.fmod(t, note_len)
		env := 1.0 - (local_t / note_len)
		val := math.sin(2.0 * math.pi * cur_note * t) * env * 20000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}

pub fn (mut sm SoundManager) play_crash() {
	sample_rate := 44100
	duration := 0.22
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 480.0 - t * 1500.0
		env := 1.0 - (t / duration)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * 0.6
		val := (math.sin(2.0 * math.pi * math.max(60.0, freq) * t) * 0.4 + noise) * env * 24000.0
		samples[i] = i16(val)
	}
	sm.play_sfx(samples)
}
