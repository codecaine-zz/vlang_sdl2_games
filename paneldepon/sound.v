module main

import math
import os
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
		'paneldepon/assets/sounds/${filename}',
		'paneldepon/assets/music/${filename}',
		'../assets/sounds/${filename}',
		'../assets/music/${filename}',
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
	sm.load_clip('bgm', 'paneldepon_bgm.wav')
	sm.load_clip('swap', 'paneldepon_swap.wav')
	sm.load_clip('match', 'paneldepon_match.wav')
	sm.load_clip('combo', 'paneldepon_combo.wav')
	sm.load_clip('raise', 'paneldepon_raise.wav')
	sm.load_clip('garbage', 'paneldepon_garbage.wav')
	sm.load_clip('warning', 'paneldepon_warning.wav')
	sm.load_clip('win', 'paneldepon_win.wav')
	sm.load_clip('lose', 'paneldepon_lose.wav')
}

fn (sm &SoundManager) play_clip(name string) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	if clip := sm.clips[name] {
		if clip.buf != unsafe { nil } && clip.len > 0 {
			sdl.queue_audio(sm.dev, clip.buf, clip.len)
		}
	}
}

fn (sm &SoundManager) update_bgm(is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 || !is_active {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev)
	if queued < 8192 {
		sm.play_clip('bgm')
	}
}

fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return mutable_sm.sound_enabled
}

fn (sm &SoundManager) play_pcm(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

// Cursor swap click
fn (sm &SoundManager) play_swap_sound() {
	if 'swap' in sm.clips {
		sm.play_clip('swap')
		return
	}
	sample_rate := 44100
	duration_ms := 30
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 520.0 + t * 4500.0
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 12000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Cursor move tick
fn (sm &SoundManager) play_move_sound() {
	sample_rate := 44100
	duration_ms := 20
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 7000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Panel match pop / musical cascade arpeggios
fn (sm &SoundManager) play_match_sound(chain int) {
	if chain > 1 && 'combo' in sm.clips {
		sm.play_clip('combo')
		return
	} else if 'match' in sm.clips {
		sm.play_clip('match')
		return
	}

	sample_rate := 44100
	duration_ms := 160 + chain * 30
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	// Pentatonic scale arpeggios based on chain reaction count
	scale := [523.25, 587.33, 659.25, 783.99, 880.0, 1046.50, 1174.66, 1318.51]
	freq := scale[chain % scale.len]

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-t * 12.0)
		s1 := math.sin(2.0 * math.pi * freq * t)
		s2 := math.sin(2.0 * math.pi * (freq * 1.5) * t) * 0.5
		s3 := math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.3
		sample := (s1 + s2 + s3) * env * 14000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Stack Manual Lift acceleration whoosh
fn (sm &SoundManager) play_lift_sound() {
	if 'raise' in sm.clips {
		sm.play_clip('raise')
		return
	}
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 180.0 + (f64(i) / f64(num_samples)) * 320.0
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 8000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_push_sound() {
	sm.play_lift_sound()
}

fn (sm &SoundManager) play_freeze_sound() {
	if 'combo' in sm.clips {
		sm.play_clip('combo')
		return
	}
	sm.play_match_sound(3)
}

// Game Over sound
fn (sm &SoundManager) play_game_over_sound() {
	if 'lose' in sm.clips {
		sm.play_clip('lose')
		return
	}
	sample_rate := 44100
	duration_ms := 400
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 340.0 - (f64(i) / f64(num_samples)) * 180.0
		env := 1.0 - (f64(i) / f64(num_samples))
		sample := math.sin(2.0 * math.pi * freq * t) * env * 12000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}
