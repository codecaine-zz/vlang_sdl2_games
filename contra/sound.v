module main

import math
import sdl

pub struct SoundManager {
pub mut:
	dev_id        u32
	sound_enabled bool = true
}

pub fn new_sound_manager() SoundManager {
	mut sm := SoundManager{}
	spec := sdl.AudioSpec{
		freq:     44100
		format:   sdl.AudioFormat(sdl.audio_s16lsb)
		channels: 1
		samples:  1024
	}
	obtained := sdl.AudioSpec{}
	sm.dev_id = sdl.open_audio_device(unsafe { nil }, 0, &spec, &obtained, 0)
	if sm.dev_id > 0 {
		sdl.pause_audio_device(sm.dev_id, 0)
	}
	return sm
}

pub fn (mut sm SoundManager) toggle_sound() {
	sm.sound_enabled = !sm.sound_enabled
}

fn (mut sm SoundManager) play_raw_samples(samples []i16) {
	if !sm.sound_enabled || sm.dev_id == 0 { return }
	sdl.clear_queued_audio(sm.dev_id)
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * 2))
}

// 1. Rifle standard shot
pub fn (mut sm SoundManager) play_rifle() {
	if !sm.sound_enabled { return }
	sample_rate := 44100
	duration := 0.08
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 750.0 - t * 4500.0
		env := 1.0 - (t / duration)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * 0.3
		val := (math.sin(2.0 * math.pi * freq * t) * 0.7 + noise) * env * 14000.0
		samples[i] = i16(val)
	}
	sm.play_raw_samples(samples)
}

// 2. Spread Gun: Massive shotgun punch with sub-bass resonance
pub fn (mut sm SoundManager) play_spread() {
	if !sm.sound_enabled { return }
	sample_rate := 44100
	duration := 0.16
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 420.0 - t * 1800.0
		env := math.pow(1.0 - (t / duration), 1.6)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * 0.55
		sub_bass := math.sin(2.0 * math.pi * 95.0 * t) * 0.6
		val := (math.sin(2.0 * math.pi * math.max(60.0, freq) * t) * 0.5 + sub_bass + noise) * env * 24000.0
		samples[i] = i16(val)
	}
	sm.play_raw_samples(samples)
}

// 3. Laser Gun: Piercing continuous plasma frequency sweep
pub fn (mut sm SoundManager) play_laser() {
	if !sm.sound_enabled { return }
	sample_rate := 44100
	duration := 0.14
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1600.0 - t * 7500.0
		mod := math.sin(2.0 * math.pi * 120.0 * t) * 400.0
		env := math.pow(1.0 - (t / duration), 0.8)
		val := math.sin(2.0 * math.pi * math.max(150.0, freq + mod) * t) * env * 19000.0
		samples[i] = i16(val)
	}
	sm.play_raw_samples(samples)
}

// 4. Fireball: Whirling flame sound with crackle
pub fn (mut sm SoundManager) play_fireball() {
	if !sm.sound_enabled { return }
	sample_rate := 44100
	duration := 0.18
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 280.0 + math.sin(2.0 * math.pi * 25.0 * t) * 120.0
		env := 1.0 - (t / duration)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * 0.4
		val := (math.sin(2.0 * math.pi * freq * t) * 0.6 + noise) * env * 20000.0
		samples[i] = i16(val)
	}
	sm.play_raw_samples(samples)
}

// 5. Jump somersault
pub fn (mut sm SoundManager) play_jump() {
	if !sm.sound_enabled { return }
	sample_rate := 44100
	duration := 0.12
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 220.0 + t * 900.0
		env := 1.0 - (t / duration)
		val := math.sin(2.0 * math.pi * freq * t) * env * 14000.0
		samples[i] = i16(val)
	}
	sm.play_raw_samples(samples)
}

// 6. Deep Multi-Tiered Explosion
pub fn (mut sm SoundManager) play_explosion() {
	if !sm.sound_enabled { return }
	sample_rate := 44100
	duration := 0.35
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.pow(1.0 - (t / duration), 1.2)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0)
		rumble := math.sin(2.0 * math.pi * 55.0 * t) * 0.5
		val := (noise * 0.7 + rumble) * env * 26000.0
		samples[i] = i16(val)
	}
	sm.play_raw_samples(samples)
}

// 7. Power-up badge pickup chime
pub fn (mut sm SoundManager) play_powerup() {
	if !sm.sound_enabled { return }
	sample_rate := 44100
	duration := 0.25
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50]
	note_len := duration / f64(notes.len)

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(t / note_len)
		cur_note := if note_idx < notes.len { notes[note_idx] } else { notes[notes.len - 1] }
		local_t := math.fmod(t, note_len)
		env := 1.0 - (local_t / note_len)
		val := math.sin(2.0 * math.pi * cur_note * t) * env * 16000.0
		samples[i] = i16(val)
	}
	sm.play_raw_samples(samples)
}

// 8. Konami Code 30 Lives chime
pub fn (mut sm SoundManager) play_konami_code() {
	if !sm.sound_enabled { return }
	sample_rate := 44100
	duration := 0.5
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	notes := [440.0, 554.37, 659.25, 880.0, 1108.73, 1318.51]
	note_len := duration / f64(notes.len)

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(t / note_len)
		cur_note := if note_idx < notes.len { notes[note_idx] } else { notes[notes.len - 1] }
		local_t := math.fmod(t, note_len)
		env := 1.0 - (local_t / note_len)
		val := math.sin(2.0 * math.pi * cur_note * t) * env * 18000.0
		samples[i] = i16(val)
	}
	sm.play_raw_samples(samples)
}

// 9. Stage Clear Fanfare
pub fn (mut sm SoundManager) play_stage_clear() {
	if !sm.sound_enabled { return }
	sample_rate := 44100
	duration := 0.7
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	notes := [523.25, 523.25, 523.25, 659.25, 783.99, 1046.50]
	note_len := duration / f64(notes.len)

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(t / note_len)
		cur_note := if note_idx < notes.len { notes[note_idx] } else { notes[notes.len - 1] }
		local_t := math.fmod(t, note_len)
		env := 1.0 - (local_t / note_len)
		val := math.sin(2.0 * math.pi * cur_note * t) * env * 18000.0
		samples[i] = i16(val)
	}
	sm.play_raw_samples(samples)
}

// 10. Commando Death Scream & Impact
pub fn (mut sm SoundManager) play_death() {
	if !sm.sound_enabled { return }
	sample_rate := 44100
	duration := 0.3
	num_samples := int(f64(sample_rate) * duration)
	mut samples := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 480.0 - t * 1200.0
		env := 1.0 - (t / duration)
		noise := (f64((i * 1103515245 + 12345) & 0x7FFF) / 32767.0 * 2.0 - 1.0) * 0.3
		val := (math.sin(2.0 * math.pi * math.max(60.0, freq) * t) + noise) * env * 18000.0
		samples[i] = i16(val)
	}
	sm.play_raw_samples(samples)
}
