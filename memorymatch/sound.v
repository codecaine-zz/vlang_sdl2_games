module main

import math
import os
import sdl

struct ActiveSfx {
mut:
	pcm    []i16
	pos    int
	volume f32
}

pub struct SoundManager {
pub mut:
	dev_id     sdl.AudioDeviceID
	enabled    bool = true
	bgm_pcm    []i16
	bgm_pos    int
	bgm_volume f32 = 0.42
	sfx_volume f32 = 0.88
	sfx_clips  map[string][]i16
	active_sfx []ActiveSfx
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
	dev := sdl.open_audio_device(unsafe { nil }, 0, &desired, &obtained, 0)
	if dev != 0 {
		sdl.pause_audio_device(dev, 0)
	}

	mut sm := SoundManager{
		dev_id:  dev
		enabled: dev != 0
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
		os.join_path('memorymatch', 'assets', 'music', filename),
		os.join_path('memorymatch', 'assets', 'sounds', filename),
		'/Users/codecaine/vlang_sdl2_games/assets/music/${filename}',
		'/Users/codecaine/vlang_sdl2_games/assets/sounds/${filename}',
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
				if name == 'bgm' {
					sm.bgm_pcm = pcm
				} else {
					sm.sfx_clips[name] = pcm
				}
				return
			}
		}
	}
}

fn (mut sm SoundManager) load_all_clips() {
	sm.load_clip('bgm', 'memorymatch_bgm.wav')
	sm.load_clip('flip', 'click.wav')
	sm.load_clip('match', 'score.wav')
	sm.load_clip('mismatch', 'bounce.wav')
	sm.load_clip('win', 'win.wav')
}

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.enabled = !sm.enabled
	if !sm.enabled && sm.dev_id != 0 {
		sdl.clear_queued_audio(sm.dev_id)
		sm.active_sfx.clear()
	}
	return sm.enabled
}

fn (mut sm SoundManager) play_sfx_pcm(pcm []i16, vol f32) {
	if !sm.enabled || sm.dev_id == 0 || pcm.len == 0 {
		return
	}
	sm.active_sfx << ActiveSfx{
		pcm:    pcm
		pos:    0
		volume: vol
	}
}

// update_bgm streams small audio chunks (~23ms) into the SDL queue,
// mixing background music and concurrent active sound effects in real time.
pub fn (sm &SoundManager) update_bgm(is_active bool) {
	if !sm.enabled || sm.dev_id == 0 {
		return
	}

	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued >= 4096 {
		return
	}

	mut mutable_sm := unsafe { &SoundManager(sm) }
	chunk_size := 1024
	mut chunk := []i16{len: chunk_size}

	for i in 0 .. chunk_size {
		mut sample_val := f32(0.0)

		// 1. Background Music Loop
		if is_active && mutable_sm.bgm_pcm.len > 0 {
			sample_val += f32(mutable_sm.bgm_pcm[mutable_sm.bgm_pos]) * mutable_sm.bgm_volume
			mutable_sm.bgm_pos++
			if mutable_sm.bgm_pos >= mutable_sm.bgm_pcm.len {
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

		// 3. Clamping Limiter
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

	sdl.queue_audio(sm.dev_id, chunk.data, u32(chunk.len * 2))
}

pub fn (sm &SoundManager) play_flip_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	// Snappy crisp card flip swoosh
	sample_rate := 44100
	duration_ms := 65
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 380.0 + 550.0 * (f64(i) / f64(num_samples))
		env := math.exp(-22.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.75)
}

pub fn (sm &SoundManager) play_match_sound(combo int) {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	// Sparkling ascending harmonic crystal chime with combo multiplier
	sample_rate := 44100
	base_freq := 523.25 * math.pow(1.08, f64(combo))
	notes := [base_freq, base_freq * 1.25, base_freq * 1.5]
	note_dur := 45
	total_samples := (sample_rate * note_dur * notes.len) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start := (sample_rate * note_dur * n_idx) / 1000
		n_samples := (sample_rate * note_dur) / 1000
		for i in 0 .. n_samples {
			t := f64(i) / f64(sample_rate)
			env := math.exp(-12.0 * t)
			harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(2.0 * math.pi * freq * 2.0 * t)
			pcm[start + i] = i16(harm * env * 22000.0)
		}
	}
	mutable_sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (sm &SoundManager) play_mismatch_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	// Gentle two-tone wooden soft wobble
	sample_rate := 44100
	duration_ms := 140
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 240.0 - 90.0 * (f64(i) / f64(num_samples))
		env := math.exp(-16.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 16000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.7)
}

pub fn (sm &SoundManager) play_win_fanfare() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	// Grand magical victory fanfare
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
	note_dur := 65
	total_samples := (sample_rate * note_dur * notes.len) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start := (sample_rate * note_dur * n_idx) / 1000
		n_samples := (sample_rate * note_dur) / 1000
		for i in 0 .. n_samples {
			t := f64(i) / f64(sample_rate)
			env := math.exp(-8.0 * t)
			harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(2.0 * math.pi * freq * 2.0 * t)
			pcm[start + i] = i16(harm * env * 24000.0)
		}
	}
	mutable_sm.play_sfx_pcm(pcm, 1.0)
}

pub fn (sm &SoundManager) play_click_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	duration_ms := 20
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-60.0 * t)
		pcm[i] = i16(math.sin(2.0 * math.pi * 750.0 * t) * env * 14000.0)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.6)
}

pub fn (mut sm SoundManager) cleanup() {
	sm.active_sfx.clear()
	sm.sfx_clips.clear()
	sm.bgm_pcm.clear()
	if sm.dev_id != 0 {
		sdl.close_audio_device(sm.dev_id)
		sm.dev_id = 0
	}
}
