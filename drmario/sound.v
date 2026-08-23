module main

import math
import os
import sdl

pub enum BgmType {
	fever
	chill
	off
}

pub struct SoundClip {
pub mut:
	buf &u8 = &u8(unsafe { nil })
	len u32
}

pub struct SoundManager {
pub mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	bgm_type      BgmType = .fever
	bgm_step      int
	bgm_phase     f64
	bgm_timer     f64
	clips         map[string]SoundClip
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

	mut sm := SoundManager{
		dev:           dev_id
		sound_enabled: dev_id != 0
	}
	sm.load_all_clips()
	return sm
}

pub fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/music/${filename}',
		'assets/sounds/${filename}',
		'../assets/music/${filename}',
		'../assets/sounds/${filename}',
		os.join_path('assets', 'music', filename),
		os.join_path('assets', 'sounds', filename),
		os.join_path('..', 'assets', 'music', filename),
		os.join_path('..', 'assets', 'sounds', filename),
		os.join_path('drmario', 'assets', 'music', filename),
		os.join_path('drmario', 'assets', 'sounds', filename),
	]
	for p in paths {
		if os.exists(p) {
			mut spec := sdl.AudioSpec{}
			mut buf := &u8(unsafe { nil })
			mut len := u32(0)
			res := sdl.load_wav(p.str, &spec, &buf, &len)
			if !isnil(res) && len > 0 {
				sm.clips[name] = SoundClip{
					buf: buf
					len: len
				}
				return
			}
		}
	}
}

pub fn (mut sm SoundManager) load_all_clips() {
	sm.load_clip('bgm_fever', 'drmario_fever.wav')
	sm.load_clip('bgm_chill', 'drmario_chill.wav')
}

pub fn (sm &SoundManager) play_clip(name string) bool {
	if !sm.sound_enabled || sm.dev == 0 {
		return false
	}
	if clip := sm.clips[name] {
		if clip.len > 0 && !isnil(clip.buf) {
			sdl.queue_audio(sm.dev, clip.buf, clip.len)
			return true
		}
	}
	return false
}

pub fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return mutable_sm.sound_enabled
}

pub fn (sm &SoundManager) set_bgm(bgm_type BgmType) {
	if sm.bgm_type == bgm_type {
		return
	}
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.bgm_type = bgm_type
	if sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	mutable_sm.bgm_step = 0
}

pub fn (sm &SoundManager) cycle_bgm() BgmType {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.bgm_type = match mutable_sm.bgm_type {
		.fever { BgmType.chill }
		.chill { BgmType.off }
		.off { BgmType.fever }
	}
	if sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	mutable_sm.bgm_step = 0
	return mutable_sm.bgm_type
}

// Background Music Engine: streams CD-quality soundtrack with procedural fallback
pub fn (sm &SoundManager) update_bgm(_dt f64, is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 || !is_active || sm.bgm_type == .off {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev)
	if queued > 16384 {
		return
	}

	clip_name := match sm.bgm_type {
		.fever { 'bgm_fever' }
		.chill { 'bgm_chill' }
		.off { '' }
	}

	if clip_name != '' && sm.play_clip(clip_name) {
		return
	}

	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100

	if sm.bgm_type == .chill {
		// Chill Theme (Authentic Mellow Latin Bossa-Nova / Jazz)
		step_duration := 0.155 // ~98 BPM smooth lounge groove
		samples_per_step := int(f64(sample_rate) * step_duration)
		mut pcm := []i16{len: samples_per_step}

		chill_lead := [
			// Phrase 1 (The iconic Chill melody)
			392.00, 440.00, 523.25, 659.25, 587.33, 523.25, 440.00, 392.00,
			329.63, 0.0, 392.00, 523.25, 440.00, 0.0, 0.0, 0.0,
			392.00, 440.00, 523.25, 659.25, 783.99, 659.25, 587.33, 523.25,
			587.33, 0.0, 659.25, 587.33, 523.25, 0.0, 0.0, 0.0,
			// Phrase 2 (Breezy swing bridge)
			659.25, 659.25, 698.46, 783.99, 880.00, 783.99, 698.46, 659.25,
			587.33, 0.0, 523.25, 440.00, 523.25, 587.33, 0.0, 0.0,
			659.25, 783.99, 880.00, 1046.50, 987.77, 880.00, 783.99, 659.25,
			523.25, 587.33, 659.25, 523.25, 440.00, 392.00, 0.0, 0.0,
		]

		chill_bass := [
			130.81, 261.63, 196.00, 261.63, 174.61, 261.63, 196.00, 130.81,
			164.81, 329.63, 220.00, 329.63, 174.61, 261.63, 196.00, 130.81,
			130.81, 261.63, 196.00, 261.63, 174.61, 261.63, 196.00, 130.81,
			146.83, 293.66, 220.00, 293.66, 196.00, 261.63, 196.00, 130.81,
			174.61, 349.23, 261.63, 349.23, 164.81, 329.63, 246.94, 329.63,
			146.83, 293.66, 220.00, 293.66, 130.81, 261.63, 196.00, 261.63,
			174.61, 349.23, 261.63, 349.23, 196.00, 392.00, 293.66, 392.00,
			130.81, 196.00, 261.63, 196.00, 174.61, 196.00, 261.63, 130.81,
		]

		step := mutable_sm.bgm_step % chill_lead.len
		lead_freq := chill_lead[step]
		bass_freq := chill_bass[step]

		for i in 0 .. samples_per_step {
			t := f64(i) / f64(sample_rate)
			progress := f64(i) / f64(samples_per_step)

			// Lead flute/vibraphone synth with smooth sine + tremolo
			mut lead_val := 0.0
			if lead_freq > 0.0 {
				vib := 1.0 + 0.02 * math.sin(2.0 * math.pi * 5.5 * t)
				s1 := math.sin(2.0 * math.pi * lead_freq * vib * t)
				s2 := math.sin(4.0 * math.pi * lead_freq * vib * t) * 0.25
				env := math.sin(math.pi * progress)
				lead_val = (s1 + s2) * env * 9000.0
			}

			// Warm Acoustic Bass
			mut bass_val := 0.0
			if bass_freq > 0.0 {
				tri := 2.0 * math.abs(2.0 * (t * bass_freq - math.floor(t * bass_freq + 0.5))) - 1.0
				b_env := math.exp(-6.0 * progress)
				bass_val = tri * b_env * 8500.0
			}

			// Soft shaker percussion
			mut drum_val := 0.0
			if step % 2 == 1 && progress < 0.18 {
				noise := (f64((i * 1103515245 + 12345) & 0x7FFFFFFF) / 2147483648.0) * 2.0 - 1.0
				drum_val = noise * (1.0 - progress / 0.18) * 2200.0
			}

			sample := lead_val + bass_val + drum_val
			pcm[i] = i16(math.max(-32000.0, math.min(32000.0, sample)))
		}

		sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
		mutable_sm.bgm_step++
		return
	}

	// Fever Theme (Authentic Fast Syncopated Funk / Tanaka classic)
	step_duration := 0.118 // ~127 BPM fast bounce
	samples_per_step := int(f64(sample_rate) * step_duration)
	mut pcm := []i16{len: samples_per_step}

	// 64-step authentic Fever Theme (Hirokazu Tanaka NES classic)
	lead_melody := [
		// Phrase 1 (The famous opening hook)
		523.25, 523.25, 622.25, 698.46, 739.99, 783.99, 1046.50, 0.0,
		932.33, 783.99, 698.46, 622.25, 698.46, 739.99, 783.99, 0.0,
		// Phrase 2 (Ascending high pop)
		523.25, 523.25, 622.25, 698.46, 739.99, 783.99, 1244.51, 0.0,
		1174.66, 1046.50, 880.00, 932.33, 987.77, 1046.50, 0.0, 0.0,
		// Phrase 3 (Funky bridge)
		783.99, 783.99, 932.33, 1046.50, 1108.73, 1174.66, 1567.98, 0.0,
		1396.91, 1174.66, 1046.50, 932.33, 1046.50, 1108.73, 1174.66, 0.0,
		// Phrase 4 (Catchy resolve)
		1244.51, 1174.66, 1046.50, 932.33, 783.99, 698.46, 622.25, 0.0,
		523.25, 622.25, 698.46, 739.99, 783.99, 932.33, 1046.50, 0.0,
	]

	harmony_melody := [
		392.00, 392.00, 466.16, 523.25, 554.37, 587.33, 783.99, 0.0,
		698.46, 587.33, 523.25, 466.16, 523.25, 554.37, 587.33, 0.0,
		392.00, 392.00, 466.16, 523.25, 554.37, 587.33, 932.33, 0.0,
		880.00, 783.99, 659.25, 698.46, 739.99, 783.99, 0.0, 0.0,
		587.33, 587.33, 698.46, 783.99, 830.61, 880.00, 1174.66, 0.0,
		1046.50, 880.00, 783.99, 698.46, 783.99, 830.61, 880.00, 0.0,
		932.33, 880.00, 783.99, 698.46, 587.33, 523.25, 466.16, 0.0,
		392.00, 466.16, 523.25, 554.37, 587.33, 698.46, 783.99, 0.0,
	]

	bass_notes := [
		130.81, 261.63, 196.00, 261.63, 155.56, 261.63, 174.61, 185.00,
		196.00, 392.00, 293.66, 392.00, 233.08, 392.00, 246.94, 392.00,
		130.81, 261.63, 196.00, 261.63, 155.56, 261.63, 174.61, 185.00,
		196.00, 392.00, 220.00, 233.08, 246.94, 261.63, 130.81, 196.00,
		196.00, 392.00, 293.66, 392.00, 233.08, 392.00, 261.63, 277.18,
		293.66, 587.33, 440.00, 587.33, 349.23, 587.33, 369.99, 587.33,
		261.63, 523.25, 392.00, 349.23, 293.66, 261.63, 233.08, 196.00,
		130.81, 155.56, 174.61, 185.00, 196.00, 233.08, 261.63, 130.81,
	]

	step := mutable_sm.bgm_step % lead_melody.len
	lead_freq := lead_melody[step]
	harm_freq := harmony_melody[step]
	bass_freq := bass_notes[step]

	for i in 0 .. samples_per_step {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-8.0 * (f64(i) / f64(samples_per_step)))

		// 1. Lead pulse wave (25% duty cycle + slight vibrato)
		mut lead := 0.0
		if lead_freq > 0.0 {
			vib := 1.0 + 0.015 * math.sin(2.0 * math.pi * 6.0 * (t + mutable_sm.bgm_phase))
			lead = if math.sin(2.0 * math.pi * lead_freq * vib * (t + mutable_sm.bgm_phase)) > 0.5 { 1.0 } else { -1.0 }
		}

		// 2. Harmony pulse wave (50% duty cycle)
		mut harm := 0.0
		if harm_freq > 0.0 {
			harm = if math.sin(2.0 * math.pi * harm_freq * (t + mutable_sm.bgm_phase)) > 0.0 { 1.0 } else { -1.0 }
		}

		// 3. Funky Triangle Bassline
		bass := math.sin(2.0 * math.pi * bass_freq * (t + mutable_sm.bgm_phase)) * math.exp(-3.0 * (f64(i) / f64(samples_per_step)))

		// 4. Punchy Drum Kit
		mut drum := 0.0
		// Snare on 4, 12, 20, 28... (every 8th step offset by 4)
		if step % 8 == 4 && i < samples_per_step / 2 {
			noise := f64((i * 1103515245 + 12345) % 65536) / 32768.0 - 1.0
			drum = noise * math.exp(-22.0 * t) * 1.5
		}
		// Bass Drum on 0, 8, 16, 24...
		else if step % 8 == 0 && i < samples_per_step / 3 {
			b_freq := 120.0 - 80.0 * (f64(i) / f64(samples_per_step / 3))
			drum = math.sin(2.0 * math.pi * b_freq * t) * math.exp(-18.0 * t) * 1.4
		}
		// Closed Hi-hat on offbeats
		else if step % 2 == 1 && i < samples_per_step / 5 {
			noise := f64((i * 1103515245 + 12345) % 65536) / 32768.0 - 1.0
			drum = noise * math.exp(-40.0 * t) * 0.7
		}

		sample_val := (lead * 0.28 * env + harm * 0.16 * env + bass * 0.28 + drum * 0.22) * 13500.0
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, sample_val)))
	}

	mutable_sm.bgm_phase += step_duration
	mutable_sm.bgm_step++
	sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
}

pub fn (sm &SoundManager) play_rotate() {
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
		freq := 740.0 + 400.0 * progress
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - progress
		pcm[i] = i16(sq * env * 11000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_drop() {
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
		freq := 340.0 - 180.0 * progress
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - progress
		pcm[i] = i16(sq * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_hard_drop() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 75
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq := 600.0 * math.exp(-30.0 * t) + 110.0
		bass := math.sin(2.0 * math.pi * freq * t) * math.exp(-15.0 * t)
		click := if math.sin(2.0 * math.pi * 900.0 * t) > 0.0 && progress < 0.2 { 1.0 } else { 0.0 }
		pcm[i] = i16((bass * 0.7 + click * 0.3) * 24000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_match(chain int) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 160
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	scale := [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
	base_idx := int(math.min(f64(chain - 1), f64(scale.len - 2)))
	f1 := scale[base_idx]
	f2 := scale[base_idx + 1]

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-12.0 * t)
		s1 := math.sin(2.0 * math.pi * f1 * t)
		s2 := math.sin(2.0 * math.pi * f2 * t) * 0.5
		s3 := math.sin(2.0 * math.pi * f1 * 2.0 * t) * 0.25
		pcm[i] = i16((s1 + s2 + s3) * env * 18000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_virus_kill(color PillColor, chain int) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	base_freq := match color {
		.red { 280.0 }
		.yellow { 440.0 }
		.blue { 350.0 }
	}
	mult := 1.0 + f64(chain - 1) * 0.15

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		env := math.exp(-8.0 * progress)

		// Frequency sweep + vibrato bubble
		freq := (base_freq * mult) + 400.0 * math.sin(progress * math.pi)
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.1 { 1.0 } else { -1.0 }
		sine := math.sin(2.0 * math.pi * freq * 1.5 * t)
		noise := (f64((i * 1103515245 + 12345) & 0xFFFF) / 32768.0 - 1.0) * (1.0 - progress) * 0.3

		sample_val := (sq * 0.5 + sine * 0.35 + noise) * env * 22000.0
		pcm[i] = i16(math.max(-32000.0, math.min(32000.0, sample_val)))
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_virus_pop() {
	sm.play_virus_kill(.red, 1)
}

pub fn (sm &SoundManager) play_combo(chain int) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 280
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq := 440.0 + 800.0 * progress + f64(chain) * 80.0
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-5.0 * progress)
		pcm[i] = i16(sq * env * 19000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_stage_clear() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 800
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98] // C5, E5, G5, C6, E6, G6
	note_len := num_samples / notes.len

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(math.min(f64(i / note_len), f64(notes.len - 1)))
		freq := notes[note_idx]
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - (f64(i % note_len) / f64(note_len)) * 0.4
		pcm[i] = i16(sq * env * 14000.0)
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

	notes := [493.88, 466.16, 440.00, 415.30, 392.00] // B4, Bb4, A4, Ab4, G4
	note_len := num_samples / notes.len

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(math.min(f64(i / note_len), f64(notes.len - 1)))
		freq := notes[note_idx]
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - (f64(i % note_len) / f64(note_len)) * 0.5
		pcm[i] = i16(sq * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}


pub fn (sm &SoundManager) play_hold() {
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
		freq := 587.33 + 300.0 * progress // D5 to F5
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - progress
		pcm[i] = i16(sq * env * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_virus_dizzy() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 250
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		wobble := math.sin(2.0 * math.pi * 14.0 * t) * 120.0
		freq := 600.0 - 350.0 * progress + wobble
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - progress
		pcm[i] = i16(sq * env * 15000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (mut sm SoundManager) cleanup() {
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
	}
	for _, clip in sm.clips {
		if !isnil(clip.buf) {
			sdl.free_wav(clip.buf)
		}
	}
}

