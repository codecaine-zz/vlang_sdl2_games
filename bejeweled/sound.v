module main

import math
import rand
import sdl
import os

pub enum BejeweledBgmType {
	cosmic_trance
	electro_rush
	zen_ambient
	off
}

struct SoundClip {
mut:
	buf &u8 = &u8(unsafe { nil })
	len u32
}

struct SoundManager {
mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	bgm_type      BejeweledBgmType = .cosmic_trance
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
		'assets/music/${filename}',
		'assets/sounds/${filename}',
		'../assets/music/${filename}',
		'../assets/sounds/${filename}',
		os.join_path('assets', 'music', filename),
		os.join_path('assets', 'sounds', filename),
		os.join_path('..', 'assets', 'music', filename),
		os.join_path('..', 'assets', 'sounds', filename),
		os.join_path('bejeweled', 'assets', 'music', filename),
		os.join_path('bejeweled', 'assets', 'sounds', filename),
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
	sm.load_clip('bgm_cosmic', 'bejeweled_bgm.wav')
	sm.load_clip('bgm_zen', 'bejeweled_zen.wav')
	sm.load_clip('bgm_blitz', 'bejeweled_blitz.wav')
	sm.load_clip('swap', 'bejeweled_swap.wav')
	sm.load_clip('bad_swap', 'bejeweled_badswap.wav')
	sm.load_clip('match', 'bejeweled_match.wav')
	sm.load_clip('combo', 'bejeweled_combo.wav')
	sm.load_clip('flame', 'bejeweled_flame.wav')
	sm.load_clip('star', 'bejeweled_star.wav')
	sm.load_clip('hypercube', 'bejeweled_hypercube.wav')
	sm.load_clip('level_up', 'bejeweled_levelup.wav')
	sm.load_clip('no_moves', 'bejeweled_nomoves.wav')
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

fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return mutable_sm.sound_enabled
}

fn (sm &SoundManager) set_bgm(bgm_type BejeweledBgmType) {
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

fn (sm &SoundManager) cycle_bgm() BejeweledBgmType {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.bgm_type = match mutable_sm.bgm_type {
		.cosmic_trance { BejeweledBgmType.electro_rush }
		.electro_rush { BejeweledBgmType.zen_ambient }
		.zen_ambient { BejeweledBgmType.off }
		.off { BejeweledBgmType.cosmic_trance }
	}
	if sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	mutable_sm.bgm_step = 0
	return mutable_sm.bgm_type
}

// Background Music Engine: streams CD-quality WAV soundtrack with real-time procedural fallback
fn (sm &SoundManager) update_bgm(_dt f64, is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 || !is_active || sm.bgm_type == .off {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev)
	if queued > 16384 {
		return
	}

	clip_name := match sm.bgm_type {
		.cosmic_trance { 'bgm_cosmic' }
		.zen_ambient { 'bgm_zen' }
		.electro_rush { 'bgm_blitz' }
		.off { '' }
	}

	if clip_name != '' && sm.play_clip(clip_name) {
		return
	}

	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100

	if sm.bgm_type == .electro_rush {
		// 135 BPM High-Octane Speed Blitz Theme
		step_dur := 0.111 // ~135 BPM
		samples_per_step := int(f64(sample_rate) * step_dur)
		mut pcm := []i16{len: samples_per_step}

		lead_notes := [
			659.25, 783.99, 987.77, 1318.51, 1174.66, 987.77, 783.99, 659.25,
			587.33, 698.46, 880.00, 1174.66, 1046.50, 880.00, 698.46, 587.33,
			523.25, 659.25, 783.99, 1046.50, 987.77, 783.99, 659.25, 523.25,
			493.88, 587.33, 739.99, 987.77, 880.00, 739.99, 587.33, 493.88,
		]
		bass_notes := [
			164.81, 164.81, 329.63, 164.81, 164.81, 164.81, 329.63, 164.81,
			146.83, 146.83, 293.66, 146.83, 146.83, 146.83, 293.66, 146.83,
			130.81, 130.81, 261.63, 130.81, 130.81, 130.81, 261.63, 130.81,
			123.47, 123.47, 246.94, 123.47, 123.47, 123.47, 246.94, 123.47,
		]

		step := mutable_sm.bgm_step % lead_notes.len
		l_freq := lead_notes[step]
		b_freq := bass_notes[step]

		for i in 0 .. samples_per_step {
			t := f64(i) / f64(sample_rate)
			prog := f64(i) / f64(samples_per_step)

			sq := if math.sin(2.0 * math.pi * l_freq * t) > 0.0 { 1.0 } else { -1.0 }
			lead := sq * math.exp(-7.0 * prog) * 7000.0

			saw := 2.0 * (t * b_freq - math.floor(t * b_freq + 0.5))
			bass := saw * math.exp(-4.5 * prog) * 8500.0

			mut drum := 0.0
			if step % 4 == 0 && prog < 0.25 {
				drum = math.sin(2.0 * math.pi * (120.0 - 80.0 * prog / 0.25) * t) * 7500.0
			} else if step % 2 == 1 && prog < 0.18 {
				drum = ((f64((i * 1103515245 + 12345) & 0x7FFFFFFF) / 2147483648.0) * 2.0 - 1.0) * 3500.0
			}

			pcm[i] = i16(math.max(-32000.0, math.min(32000.0, lead + bass + drum)))
		}

		sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
		mutable_sm.bgm_step++
		return
	} else if sm.bgm_type == .zen_ambient {
		// Ethereal Zen Meditation Chime Pad
		step_dur := 0.320 // Slow relaxing tempo
		samples_per_step := int(f64(sample_rate) * step_dur)
		mut pcm := []i16{len: samples_per_step}

		zen_chords := [
			261.63, 329.63, 392.00, 523.25, 659.25, 523.25, 392.00, 329.63,
			220.00, 261.63, 329.63, 440.00, 523.25, 440.00, 329.63, 261.63,
			174.61, 220.00, 261.63, 349.23, 440.00, 349.23, 261.63, 220.00,
			196.00, 246.94, 293.66, 392.00, 493.88, 392.00, 293.66, 246.94,
		]

		step := mutable_sm.bgm_step % zen_chords.len
		freq := zen_chords[step]
		drone_freq := if step < 8 { 130.81 } else if step < 16 { 110.00 } else if step < 24 { 87.31 } else { 98.00 }

		for i in 0 .. samples_per_step {
			t := f64(i) / f64(sample_rate)
			prog := f64(i) / f64(samples_per_step)

			// Bell crystal chime
			bell := math.sin(2.0 * math.pi * freq * t) * math.exp(-3.0 * prog) * 7500.0
			bell_shimmer := math.sin(2.0 * math.pi * freq * 2.76 * t) * math.exp(-4.5 * prog) * 3500.0
			drone := math.sin(2.0 * math.pi * drone_freq * t) * 6000.0

			pcm[i] = i16(math.max(-32000.0, math.min(32000.0, bell + bell_shimmer + drone)))
		}

		sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
		mutable_sm.bgm_step++
		return
	}

	// Default: Iconic Cosmic Trance Suite (Bejeweled 3 / Twist Suite Arpeggios)
	step_dur := 0.125 // ~120 BPM
	samples_per_step := int(f64(sample_rate) * step_dur)
	mut pcm := []i16{len: samples_per_step}

	trance_lead := [
		523.25, 659.25, 783.99, 1046.50, 783.99, 659.25, 1046.50, 1318.51,
		440.00, 523.25, 659.25, 880.00, 659.25, 523.25, 880.00, 1046.50,
		349.23, 440.00, 523.25, 698.46, 523.25, 440.00, 698.46, 880.00,
		392.00, 493.88, 587.33, 783.99, 587.33, 493.88, 783.99, 987.77,
	]
	trance_bass := [
		130.81, 130.81, 261.63, 130.81, 130.81, 130.81, 261.63, 130.81,
		110.00, 110.00, 220.00, 110.00, 110.00, 110.00, 220.00, 110.00,
		87.31, 87.31, 174.61, 87.31, 87.31, 87.31, 174.61, 87.31,
		98.00, 98.00, 196.00, 98.00, 98.00, 98.00, 196.00, 98.00,
	]

	step := mutable_sm.bgm_step % trance_lead.len
	l_freq := trance_lead[step]
	b_freq := trance_bass[step]

	for i in 0 .. samples_per_step {
		t := f64(i) / f64(sample_rate)
		prog := f64(i) / f64(samples_per_step)

		// Crystal square/sine lead with smooth vibrato
		vib := 1.0 + 0.015 * math.sin(2.0 * math.pi * 6.0 * t)
		sq := if math.sin(2.0 * math.pi * (l_freq * vib) * t) > 0.0 { 1.0 } else { -1.0 }
		harm := math.sin(2.0 * math.pi * (l_freq * 2.0 * vib) * t)
		lead := (sq * 0.65 + harm * 0.35) * math.exp(-6.5 * prog) * 8000.0

		// Warm resonant triangle bass
		tri := 2.0 * math.abs(2.0 * (t * b_freq - math.floor(t * b_freq + 0.5))) - 1.0
		bass := tri * math.exp(-4.0 * prog) * 8500.0

		// Cosmic electronic rhythm
		mut drum := 0.0
		if step % 4 == 0 && prog < 0.20 {
			drum = math.sin(2.0 * math.pi * (110.0 - 75.0 * prog / 0.20) * t) * 7000.0
		} else if step % 2 == 1 && prog < 0.15 {
			drum = ((f64((i * 1103515245 + 12345) & 0x7FFFFFFF) / 2147483648.0) * 2.0 - 1.0) * 3000.0
		}

		pcm[i] = i16(math.max(-32000.0, math.min(32000.0, lead + bass + drum)))
	}

	sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
	mutable_sm.bgm_step++
}

fn (sm &SoundManager) play_pcm(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

fn (sm &SoundManager) play_select_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 35
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1250.0
		env := math.exp(-45.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)
		sample := harm * env * attack * 14000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_swap_sound() {
	if sm.play_clip('swap') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 45
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 480.0 + (320.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-32.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)
		sample := harm * env * attack * 12000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_match_sound(combo int) {
	if combo > 1 {
		if sm.play_clip('combo') {
			return
		}
	} else {
		if sm.play_clip('match') {
			return
		}
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 160
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	// Pentatonic scale base frequencies: C5, D5, E5, G5, A5, C6, D6, E6
	scale := [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51]
	idx := math.min(combo - 1, scale.len - 1)
	base_freq := scale[math.max(0, idx)]

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-12.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		// Fundamental + bell harmonics
		harm := math.sin(2.0 * math.pi * base_freq * t) * 0.7 +
			math.sin(2.0 * math.pi * base_freq * 2.0 * t) * 0.3 +
			math.sin(2.0 * math.pi * base_freq * 3.0 * t) * 0.15
		sample := harm * env * attack * 20000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_flame_explosion_sound() {
	if sm.play_clip('flame') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 280
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 180.0 - (130.0 * (f64(i) / f64(num_samples)))
		noise := (rand.f64() * 2.0 - 1.0)
		env := math.exp(-8.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		sample := (math.sin(2.0 * math.pi * freq * t) * 0.4 + noise * 0.6) * env * attack * 24000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_hypercube_zap_sound() {
	if sm.play_clip('hypercube') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 320
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 220.0 + (1300.0 * math.sin(45.0 * math.pi * t))
		env := math.exp(-6.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
		sample := harm * env * attack * 20000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_win_sound() {
	if sm.play_clip('level_up') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 420
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	note_len := num_samples / notes.len
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		note_idx := math.min(i / note_len, notes.len - 1)
		freq := notes[note_idx]
		local_i := i % note_len
		t_note := f64(local_i) / f64(sample_rate)
		decay := if note_idx == notes.len - 1 { -6.0 } else { -10.0 }
		env := math.exp(decay * t_note)
		attack := if local_i < attack_samples { f64(local_i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t_note) + 0.35 * math.sin(4.0 * math.pi * freq * t_note)
		sample := harm * env * attack * 20000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_invalid_sound() {
	if sm.play_clip('bad_swap') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 70
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 180.0
		env := math.exp(-32.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		sample := math.sin(2.0 * math.pi * freq * t) * env * attack * 14000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_star_laser_sound() {
	if sm.play_clip('star') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 340
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 900.0 - 650.0 * (f64(i) / f64(num_samples))
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-6.0 * t)
		noise := (rand.f64() * 2.0 - 1.0) * 0.3
		pcm[i] = i16((sq * 0.7 + noise) * env * 22000.0)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_supernova_sound() {
	if sm.play_clip('flame') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 550
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 350.0 - 280.0 * (f64(i) / f64(num_samples))
		rumble := math.sin(2.0 * math.pi * freq * t)
		noise := (rand.f64() * 2.0 - 1.0)
		env := math.exp(-3.5 * t)
		pcm[i] = i16((rumble * 0.5 + noise * 0.5) * env * 26000.0)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_level_up_sound() {
	if sm.play_clip('level_up') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 480
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
	note_len := num_samples / notes.len

	for i in 0 .. num_samples {
		n_idx := math.min(i / note_len, notes.len - 1)
		freq := notes[n_idx]
		loc_i := i % note_len
		t := f64(loc_i) / f64(sample_rate)
		env := math.exp(-8.0 * t)
		harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
		pcm[i] = i16(harm * env * 20000.0)
	}
	sm.play_pcm(pcm)
}

fn (mut sm SoundManager) cleanup() {
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
	}
	for _, clip in sm.clips {
		if !isnil(clip.buf) {
			sdl.free_wav(clip.buf)
		}
	}
}
