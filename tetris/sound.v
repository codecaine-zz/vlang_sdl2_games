module main

import math
import os
import sdl

enum BgmType {
	type_a
	type_b
	type_c
	off
}

struct ActiveSfx {
mut:
	pcm    []i16
	pos    int
	volume f32
}

struct SoundManager {
mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	bgm_type      BgmType = .type_a
	bgm_tracks    map[BgmType][]i16
	bgm_pos       int
	bgm_volume    f32 = 0.45
	sfx_volume    f32 = 0.85
	sfx_clips     map[string][]i16
	active_sfx    []ActiveSfx
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
		os.join_path('tetris', 'assets', 'sounds', filename),
		os.join_path('tetris', 'assets', 'music', filename),
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
				num_samples := int(len / 2)
				mut pcm := []i16{len: num_samples}
				unsafe {
					vmemcpy(pcm.data, buf, int(len))
				}
				sdl.free_wav(buf)
				match name {
					'bgm_type_a' { sm.bgm_tracks[.type_a] = pcm }
					'bgm_type_b' { sm.bgm_tracks[.type_b] = pcm }
					'bgm_type_c' { sm.bgm_tracks[.type_c] = pcm }
					else { sm.sfx_clips[name] = pcm }
				}
				return
			}
		}
	}
}

fn (mut sm SoundManager) load_all_clips() {
	// Sound Effects
	sm.load_clip('move', 'click.wav')
	sm.load_clip('rotate', 'bounce.wav')
	sm.load_clip('lock', 'hit.wav')
	sm.load_clip('drop', 'impact.wav')
	sm.load_clip('clear', 'score.wav')
	sm.load_clip('tetris', 'win.wav')
	sm.load_clip('gameover', 'die.wav')

	// Classic Soundtracks
	sm.load_clip('bgm_type_a', 'tetris_type_a.wav')
	sm.load_clip('bgm_type_b', 'tetris_type_b.wav')
	sm.load_clip('bgm_type_c', 'tetris_type_c.wav')

	// Fallback alias if needed
	if BgmType.type_a !in sm.bgm_tracks {
		sm.load_clip('bgm_type_a', 'tetris_bgm.wav')
	}
}

pub fn (sm &SoundManager) cycle_bgm() BgmType {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.bgm_type = match mutable_sm.bgm_type {
		.type_a { BgmType.type_b }
		.type_b { BgmType.type_c }
		.type_c { BgmType.off }
		.off { BgmType.type_a }
	}
	mutable_sm.bgm_pos = 0
	if sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return mutable_sm.bgm_type
}

pub fn (sm &SoundManager) set_bgm(bgm_type BgmType) {
	if sm.bgm_type == bgm_type {
		return
	}
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.bgm_type = bgm_type
	mutable_sm.bgm_pos = 0
	if sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
}

pub fn (sm &SoundManager) get_bgm_title() string {
	return match sm.bgm_type {
		.type_a { 'TYPE A (KOROBEINIKI)' }
		.type_b { 'TYPE B (TROIKA)' }
		.type_c { 'TYPE C (BACH)' }
		.off { 'MUSIC: OFF' }
	}
}

fn (mut sm SoundManager) play_sfx_pcm(pcm []i16, vol f32) {
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sm.active_sfx << ActiveSfx{
		pcm:    pcm
		pos:    0
		volume: vol
	}
}

fn (mut sm SoundManager) play_clip_sfx(name string, default_vol f32) bool {
	if !sm.sound_enabled || sm.dev == 0 {
		return false
	}
	if pcm := sm.sfx_clips[name] {
		if pcm.len > 0 {
			sm.play_sfx_pcm(pcm, default_vol)
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
		mutable_sm.active_sfx.clear()
	}
	return mutable_sm.sound_enabled
}

// update_bgm streams small audio chunks (~23ms) into the SDL queue,
// mixing the selected background music track and concurrent sound effects in real time.
fn (sm &SoundManager) update_bgm(is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}

	queued := sdl.get_queued_audio_size(sm.dev)
	if queued >= 4096 {
		return
	}

	mut mutable_sm := unsafe { &SoundManager(sm) }
	chunk_size := 1024
	mut chunk := []i16{len: chunk_size}

	mut bgm_data := []i16{}
	if sm.bgm_type in mutable_sm.bgm_tracks {
		bgm_data = mutable_sm.bgm_tracks[sm.bgm_type]
	}

	for i in 0 .. chunk_size {
		mut sample_val := f32(0.0)

		// 1. Background Music Loop
		if is_active && sm.bgm_type != .off && bgm_data.len > 0 {
			sample_val += f32(bgm_data[mutable_sm.bgm_pos]) * mutable_sm.bgm_volume
			mutable_sm.bgm_pos++
			if mutable_sm.bgm_pos >= bgm_data.len {
				mutable_sm.bgm_pos = 0
			}
		}

		// 2. Active Concurrent Sound Effects
		for mut sfx in mutable_sm.active_sfx {
			if sfx.pos < sfx.pcm.len {
				sample_val += f32(sfx.pcm[sfx.pos]) * sfx.volume * mutable_sm.sfx_volume
				sfx.pos++
			}
		}

		// 3. Dynamic Soft Limiter / Clamping
		if sample_val > 32767.0 {
			sample_val = 32767.0
		} else if sample_val < -32768.0 {
			sample_val = -32768.0
		}
		chunk[i] = i16(sample_val)
	}

	// 4. Prune completed sound effects
	for idx := mutable_sm.active_sfx.len - 1; idx >= 0; idx-- {
		if mutable_sm.active_sfx[idx].pos >= mutable_sm.active_sfx[idx].pcm.len {
			mutable_sm.active_sfx.delete(idx)
		}
	}

	sdl.queue_audio(sm.dev, chunk.data, u32(chunk.len * 2))
}

fn (sm &SoundManager) play_move_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip_sfx('move', 0.6) {
		return
	}
	sample_rate := 44100
	duration_ms := 25
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-65.0 * t)
		val := math.sin(2.0 * math.pi * 420.0 * t) * env * 14000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.6)
}

fn (sm &SoundManager) play_rotate_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip_sfx('rotate', 0.75) {
		return
	}
	sample_rate := 44100
	duration_ms := 35
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 520.0 + (220.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-40.0 * t)
		val := (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env * 18000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.75)
}

fn (sm &SoundManager) play_drop_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip_sfx('drop', 0.85) || mutable_sm.play_clip_sfx('lock', 0.85) {
		return
	}
	sample_rate := 44100
	duration_ms := 45
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := math.max(60.0, 240.0 - (180.0 * (f64(i) / f64(num_samples))))
		env := math.exp(-32.0 * t)
		val := (math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)) * env * 22000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.85)
}

fn (sm &SoundManager) play_clear_sound(lines int) {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if lines >= 4 {
		if mutable_sm.play_clip_sfx('tetris', 1.0) {
			return
		}
	} else {
		if mutable_sm.play_clip_sfx('clear', 0.85) {
			return
		}
	}

	sample_rate := 44100
	if lines >= 4 {
		notes := [523.25, 659.25, 783.99, 1046.50]
		note_dur := 65
		total_samples := (sample_rate * note_dur * notes.len) / 1000
		mut pcm := []i16{len: total_samples}
		for n_idx, freq in notes {
			start := (sample_rate * note_dur * n_idx) / 1000
			n_samples := (sample_rate * note_dur) / 1000
			for i in 0 .. n_samples {
				t := f64(i) / f64(sample_rate)
				env := math.exp(-8.0 * t)
				harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
				pcm[start + i] = i16(harm * env * 22000.0)
			}
		}
		mutable_sm.play_sfx_pcm(pcm, 1.0)
	} else {
		duration_ms := 90 + lines * 30
		num_samples := (sample_rate * duration_ms) / 1000
		mut pcm := []i16{len: num_samples}
		base_freq := 440.0 + f64(lines) * 110.0
		for i in 0 .. num_samples {
			t := f64(i) / f64(sample_rate)
			env := math.exp(-12.0 * t)
			harm := math.sin(2.0 * math.pi * base_freq * t) + 0.3 * math.sin(4.0 * math.pi * base_freq * 1.5 * t)
			pcm[i] = i16(harm * env * 20000.0)
		}
		mutable_sm.play_sfx_pcm(pcm, 0.85)
	}
}

fn (sm &SoundManager) play_game_over_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip_sfx('gameover', 0.9) {
		return
	}
	sample_rate := 44100
	duration_ms := 420
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := math.max(60.0, 360.0 - (280.0 * (f64(i) / f64(num_samples))))
		env := math.exp(-4.5 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 22000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.9)
}

fn (sm &SoundManager) play_hold_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	duration_ms := 30
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-50.0 * t)
		val := math.sin(2.0 * math.pi * 480.0 * t) * env * 16000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.7)
}

fn (sm &SoundManager) play_level_up_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	notes := [440.0, 554.37, 659.25, 880.0]
	note_dur := 50
	total_samples := (sample_rate * note_dur * notes.len) / 1000
	mut pcm := []i16{len: total_samples}
	for n_idx, freq in notes {
		start := (sample_rate * note_dur * n_idx) / 1000
		n_samples := (sample_rate * note_dur) / 1000
		for i in 0 .. n_samples {
			t := f64(i) / f64(sample_rate)
			env := math.exp(-10.0 * t)
			pcm[start + i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 20000.0)
		}
	}
	mutable_sm.play_sfx_pcm(pcm, 0.85)
}

fn (sm &SoundManager) play_click_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	duration_ms := 20
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-60.0 * t)
		pcm[i] = i16(math.sin(2.0 * math.pi * 800.0 * t) * env * 14000.0)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.6)
}

fn (mut sm SoundManager) cleanup() {
	sm.active_sfx.clear()
	sm.sfx_clips.clear()
	sm.bgm_tracks.clear()
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
		sm.dev = 0
	}
}
