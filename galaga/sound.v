module main

import os
import math
import sdl

struct SoundClip {
mut:
	buf &u8 = &u8(unsafe { nil })
	len u32
}

struct SoundManager {
mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	bgm_step      int
	bgm_phase     f64
	clips         map[string]SoundClip
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
		sdl.pause_audio_device(dev_id, 0)
	}

	mut sm := SoundManager{
		dev:           dev_id
		sound_enabled: dev_id != 0
	}
	sm.load_all_clips()
	return sm
}

fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/sounds/${filename}',
		'assets/music/${filename}',
		'../assets/sounds/${filename}',
		'../assets/music/${filename}',
		os.join_path('assets', 'sounds', filename),
		os.join_path('assets', 'music', filename),
		os.join_path('..', 'assets', 'sounds', filename),
		os.join_path('..', 'assets', 'music', filename),
		os.join_path('galaga', 'assets', 'sounds', filename),
		os.join_path('galaga', 'assets', 'music', filename),
		'/Users/codecaine/vlang_sdl2_games/assets/sounds/${filename}',
		'/Users/codecaine/vlang_sdl2_games/assets/music/${filename}',
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

fn (mut sm SoundManager) load_all_clips() {
	sm.load_clip('laser', 'laser.wav')
	sm.load_clip('explosion', 'explosion.wav')
	sm.load_clip('tractor', 'ufo.wav')
	sm.load_clip('hit', 'hit.wav')
	sm.load_clip('start', 'win.wav')
	sm.load_clip('bgm', 'galaga_bgm.wav')
}

fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return mutable_sm.sound_enabled
}

fn (sm &SoundManager) update_bgm(is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 || !is_active {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev)
	if queued > 16384 {
		return
	}
	if sm.play_clip('bgm') {
		return
	}

	// Procedural 130 BPM Galaga Synth fallback if WAV is missing
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	step_dur := 0.115 // 16th note at ~130 BPM
	samples_per_step := int(f64(sample_rate) * step_dur)
	mut pcm := []i16{len: samples_per_step}

	lead_notes := [
		783.99, 1046.50, 1318.51, 1567.98, 2093.00, 1567.98, 1318.51, 1567.98,
		932.33, 1174.66, 1396.91, 1864.66, 2349.32, 1864.66, 1396.91, 1864.66,
		880.00, 1046.50, 1396.91, 1760.00, 2093.00, 1760.00, 1396.91, 1760.00,
		783.99, 987.77, 1174.66, 1567.98, 1975.53, 1567.98, 1174.66, 987.77,
	]
	bass_notes := [
		130.81, 261.63, 196.00, 261.63, 130.81, 261.63, 196.00, 261.63,
		116.54, 233.08, 174.61, 233.08, 116.54, 233.08, 174.61, 233.08,
		110.00, 220.00, 164.81, 220.00, 110.00, 220.00, 164.81, 220.00,
		123.47, 246.94, 185.00, 246.94, 123.47, 246.94, 185.00, 246.94,
	]

	step := mutable_sm.bgm_step % lead_notes.len
	l_freq := lead_notes[step]
	b_freq := bass_notes[step]

	for i in 0 .. samples_per_step {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-8.0 * (f64(i) / f64(samples_per_step)))
		lead := if math.sin(2.0 * math.pi * l_freq * (t + mutable_sm.bgm_phase)) > 0.4 { 1.0 } else { -1.0 }
		bass := math.sin(2.0 * math.pi * b_freq * (t + mutable_sm.bgm_phase)) * math.exp(-4.0 * (f64(i) / f64(samples_per_step)))
		val := (lead * 0.3 * env + bass * 0.4) * 14000.0
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, val)))
	}
	mutable_sm.bgm_phase += step_dur
	mutable_sm.bgm_step++
	sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
}

fn (sm &SoundManager) play_clip(name string) bool {
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

fn (sm &SoundManager) play_pcm(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

pub fn (sm &SoundManager) play_shoot_sound(is_dual bool) {
	if sm.play_clip('laser') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := if is_dual { 90 } else { 65 }
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq1 := 1450.0 - (950.0 * progress)
		env := math.exp(-18.0 * t)
		mut s := math.sin(2.0 * math.pi * freq1 * t)
		if is_dual {
			freq2 := 1150.0 - (750.0 * progress)
			s = (s + math.sin(2.0 * math.pi * freq2 * t)) * 0.6
		}
		pcm[i] = i16(s * env * 21000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_enemy_dive() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 260
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		// Frequency drop with classic pitch vibrato modulation
		vib := 1.0 + 0.12 * math.sin(2.0 * math.pi * 32.0 * t)
		freq := (1600.0 - 1100.0 * progress) * vib
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - 0.7 * progress
		pcm[i] = i16(sq * env * 12000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_enemy_bullet() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 45
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		freq := 900.0 - 650.0 * progress
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.2 { 1.0 } else { -1.0 }
		env := math.exp(-25.0 * t)
		pcm[i] = i16(sq * env * 11000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_kill_enemy(enemy_type EnemyType, is_diving bool) {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := match enemy_type {
		.zako { 150 }
		.goei { 200 }
		.boss { if is_diving { 380 } else { 280 } }
	}
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		noise := (f64((i * 1103515245 + 12345) & 0xFFFF) / 32768.0 - 1.0)
		decay := match enemy_type {
			.zako { -16.0 }
			.goei { -12.0 }
			.boss { -7.0 }
		}
		env := math.exp(decay * progress)

		f_sweep := match enemy_type {
			.zako { 500.0 - 320.0 * progress }
			.goei { 350.0 - 240.0 * progress }
			.boss { 200.0 - 150.0 * progress }
		}
		tone := math.sin(2.0 * math.pi * f_sweep * t)
		val := (noise * 0.65 + tone * 0.35) * env * 24000.0
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, val)))
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_explosion_sound() {
	sm.play_kill_enemy(.zako, false)
}

pub fn (sm &SoundManager) play_boss_hit() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 55
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-35.0 * t)
		ring := math.sin(2.0 * math.pi * 1850.0 * t) * 0.7 + math.sin(2.0 * math.pi * 2770.0 * t) * 0.3
		pcm[i] = i16(ring * env * 22000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_hit_sound() {
	sm.play_boss_hit()
}

pub fn (sm &SoundManager) play_tractor_beam_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		amp := 0.6 + 0.4 * math.sin(2.0 * math.pi * 14.0 * t)
		freq := 380.0 + 80.0 * math.sin(2.0 * math.pi * 7.0 * t)
		saw := 2.0 * (t * freq - math.floor(t * freq + 0.5))
		pcm[i] = i16(saw * amp * 13000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_player_captured() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 480
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		// Spiraling alarm steps
		step := int(progress * 12.0)
		freq := 880.0 * math.pow(0.85, f64(step))
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := 1.0 - 0.4 * progress
		pcm[i] = i16(sq * env * 17000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_rescue_fanfare() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50, 1567.98] // C5, E5, G5, C6, G6
	note_dur_ms := 75
	total_samples := (sample_rate * (note_dur_ms * notes.len)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_samples := (sample_rate * note_dur_ms) / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-8.0 * (f64(i) / f64(note_samples)))
			p1 := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
			sine := math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.3
			pcm[start_sample + i] = i16((p1 * 0.7 + sine) * env * 22000.0)
		}
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_player_death() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 550
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		progress := f64(i) / f64(num_samples)
		noise := (f64((i * 1103515245 + 12345) & 0xFFFF) / 32768.0 - 1.0)
		sub := math.sin(2.0 * math.pi * (180.0 * math.exp(-6.0 * t)) * t)
		env := math.exp(-4.5 * progress)
		pcm[i] = i16((noise * 0.6 + sub * 0.4) * env * 28000.0)
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_stage_start_sound() {
	if sm.play_clip('start') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	notes := [440.0, 554.37, 659.25, 880.0]
	note_dur_ms := 80
	total_samples := (sample_rate * (note_dur_ms * 3 + 160)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_dur := if n_idx == notes.len - 1 { 160 } else { note_dur_ms }
		note_samples := (sample_rate * note_dur) / 1000
		attack_samples := sample_rate * 2 / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples { break }
			t := f64(i) / f64(sample_rate)
			decay := if n_idx == notes.len - 1 { -6.0 } else { -10.0 }
			env := math.exp(decay * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
			pcm[start_sample + i] = i16(harm * env * attack * 20000.0)
		}
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_stage_clear_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50, 1174.66, 1318.51] // C5 to E6
	note_dur_ms := 70
	total_samples := (sample_rate * (note_dur_ms * notes.len + 120)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_dur := if n_idx == notes.len - 1 { note_dur_ms + 120 } else { note_dur_ms }
		note_samples := (sample_rate * note_dur) / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-6.0 * (f64(i) / f64(note_samples)))
			p := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
			pcm[start_sample + i] = i16(p * env * 19000.0)
		}
	}
	sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_game_over_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	notes := [440.0, 415.30, 392.00, 349.23] // A4, Ab4, G4, F4
	note_dur_ms := 140
	total_samples := (sample_rate * (note_dur_ms * notes.len)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_samples := (sample_rate * note_dur_ms) / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-5.0 * (f64(i) / f64(note_samples)))
			p := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
			pcm[start_sample + i] = i16(p * env * 18000.0)
		}
	}
	sm.play_pcm(pcm)
}

fn (mut sm SoundManager) cleanup() {
	for _, clip in sm.clips {
		if !isnil(clip.buf) {
			sdl.free_wav(clip.buf)
		}
	}
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
		sm.dev = 0
	}
}
