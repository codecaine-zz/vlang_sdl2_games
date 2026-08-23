module main

import os
import math
import sdl

struct SoundClip {
mut:
	buf &u8 = &u8(unsafe { nil })
	len u32
}

enum PfBgmTrack {
	arcade_battle
	super_turbo
	off
}

struct SoundManager {
mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	bgm_enabled   bool = true
	bgm_track     PfBgmTrack = .arcade_battle
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
		bgm_enabled:   dev_id != 0
	}
	sm.load_all_clips()
	return sm
}

fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/sounds/${filename}',
		'../assets/sounds/${filename}',
		'sounds/${filename}',
		'/Users/codecaine/vland_sdl2_games/assets/sounds/${filename}'
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
	sm.load_clip('hit', 'hit.wav')
	sm.load_clip('explosion', 'explosion.wav')
	sm.load_clip('score', 'score.wav')
	sm.load_clip('laser', 'laser.wav')
	sm.load_clip('bounce', 'bounce.wav')
	sm.load_clip('powerup', 'powerup.wav')
	sm.load_clip('win', 'win.wav')
	sm.load_clip('click', 'click.wav')
	sm.load_clip('die', 'die.wav')
}

fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return mutable_sm.sound_enabled
}

fn (sm &SoundManager) toggle_bgm() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.bgm_enabled = !mutable_sm.bgm_enabled
	if !mutable_sm.bgm_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return mutable_sm.bgm_enabled
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

// Background Music Synthesizer & Streamer
fn (sm &SoundManager) update_bgm(_dt f64, is_active bool) {
	if !sm.sound_enabled || !sm.bgm_enabled || sm.dev == 0 || !is_active || sm.bgm_track == .off {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev)
	if queued > u32(44100 * 2 / 5) {
		return
	}

	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100

	// 140 BPM High-Energy Capcom Arcade Fight Theme
	step_dur := 0.107 // ~140 BPM sixteenth notes
	samples_per_step := int(f64(sample_rate) * step_dur)
	mut pcm := []i16{len: samples_per_step}

	// Street Fighter inspired driving pentatonic melody
	lead_notes := [
		587.33, 659.25, 698.46, 880.00, 783.99, 659.25, 587.33, 523.25,
		587.33, 698.46, 880.00, 1046.50, 987.77, 880.00, 698.46, 783.99,
		880.00, 1046.50, 1174.66, 1318.51, 1174.66, 1046.50, 880.00, 783.99,
		698.46, 783.99, 880.00, 1046.50, 880.00, 698.46, 587.33, 523.25,
	]
	bass_notes := [
		146.83, 146.83, 293.66, 146.83, 146.83, 146.83, 293.66, 146.83,
		174.61, 174.61, 349.23, 174.61, 174.61, 174.61, 349.23, 174.61,
		220.00, 220.00, 440.00, 220.00, 220.00, 220.00, 440.00, 220.00,
		130.81, 130.81, 261.63, 130.81, 196.00, 196.00, 392.00, 196.00,
	]

	step := mutable_sm.bgm_step % lead_notes.len
	l_freq := lead_notes[step]
	b_freq := bass_notes[step]

	for i in 0 .. samples_per_step {
		t := f64(i) / f64(sample_rate)
		prog := f64(i) / f64(samples_per_step)

		// Lead Chiptune Square Synth
		sq := if math.sin(2.0 * math.pi * l_freq * t) > 0.0 { 0.8 } else { -0.8 }
		lead := sq * math.exp(-6.0 * prog) * 4500.0

		// Sawtooth Bassline
		saw := 2.0 * (t * b_freq - math.floor(t * b_freq + 0.5))
		bass := saw * math.exp(-4.0 * prog) * 5500.0

		// Snare / Kick Drums
		mut drum := 0.0
		if step % 4 == 0 && prog < 0.22 {
			drum = math.sin(2.0 * math.pi * (130.0 - 90.0 * prog / 0.22) * t) * 6000.0
		} else if step % 2 == 1 && prog < 0.16 {
			noise := ((f64((i * 1103515245 + 12345) & 0x7FFFFFFF) / 2147483648.0) * 2.0 - 1.0)
			drum = noise * math.exp(-12.0 * prog) * 3200.0
		}

		val := lead + bass + drum
		pcm[i] = i16(math.max(-30000.0, math.min(30000.0, val)))
	}

	sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
	mutable_sm.bgm_step++
}

// Rotation sound
fn (sm &SoundManager) play_rotate_sound() {
	if sm.play_clip('bounce') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 35
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 480.0 + t * 3500.0
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 11000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Move sound
fn (sm &SoundManager) play_move_sound() {
	if sm.play_clip('click') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 25
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 380.0
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 8000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Land / Lock sound
fn (sm &SoundManager) play_land_sound() {
	if sm.play_clip('hit') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 50
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 180.0 * (1.0 - t * 3.0)
		env := math.exp(-t * 30.0)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 14000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Crash Orb detonation / Fighting impact hit
fn (sm &SoundManager) play_crash_sound(chain int) {
	if chain >= 2 {
		if sm.play_clip('explosion') {
			return
		}
	} else {
		if sm.play_clip('hit') {
			return
		}
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 220 + chain * 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	base_freq := 300.0 * math.pow(1.2, f64(chain - 1))

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-t * 12.0)
		s1 := math.sin(2.0 * math.pi * base_freq * t)
		s2 := (math.sin(2.0 * math.pi * (base_freq * 1.5) * t)) * 0.6
		noise := (f64(i % 17) / 8.5 - 1.0) * 0.4
		sample := (s1 + s2 + noise) * env * 18000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Hadouken / Energy Shot Fireball
fn (sm &SoundManager) play_hadouken_sound() {
	if sm.play_clip('laser') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 950.0 - 600.0 * (f64(i) / f64(num_samples))
		env := math.exp(-8.0 * t)
		sample := (math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)) * env * 22000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Super Combo Charged Fanfare
fn (sm &SoundManager) play_super_combo_sound() {
	if sm.play_clip('powerup') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_dur := 40
	num_samples := (sample_rate * note_dur * notes.len) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000

	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-12.0 * t)
			harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
			pcm[sample_idx] = i16(harm * env * 22000.0)
		}
	}
	sm.play_pcm(pcm)
}

// Garbage Counter Gem Drop
fn (sm &SoundManager) play_garbage_drop_sound() {
	if sm.play_clip('hit') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 140
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 160.0 + (t * 800.0)
		env := math.exp(-t * 15.0)
		sqr := if (int(t * freq * 2.0) % 2) == 0 { 1.0 } else { -1.0 }
		sample := sqr * env * 13000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Knockout / Round Win Bell
fn (sm &SoundManager) play_ko_sound() {
	if sm.play_clip('win') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 600
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 880.0
		env := math.exp(-t * 5.0)
		s1 := math.sin(2.0 * math.pi * freq * t)
		s2 := math.sin(2.0 * math.pi * freq * 2.75 * t) * 0.4
		sample := (s1 + s2) * env * 17000.0
		pcm[i] = i16(sample)
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
