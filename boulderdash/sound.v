module main

import math
import os
import rand
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
		'boulderdash/assets/sounds/${filename}',
		'boulderdash/assets/music/${filename}',
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
	sm.load_clip('bgm', 'boulderdash_bgm.wav')
	sm.load_clip('dig', 'boulderdash_dig.wav')
	sm.load_clip('diamond', 'boulderdash_diamond.wav')
	sm.load_clip('boulder', 'boulderdash_boulder.wav')
	sm.load_clip('explode', 'boulderdash_explode.wav')
	sm.load_clip('door', 'boulderdash_door.wav')
	sm.load_clip('amoeba', 'boulderdash_amoeba.wav')
	sm.load_clip('die', 'boulderdash_die.wav')
	sm.load_clip('win', 'boulderdash_win.wav')
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

fn (sm &SoundManager) play_dig_sound() {
	if 'dig' in sm.clips {
		sm.play_clip('dig')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		env := math.exp(-40.0 * t)
		sample := noise * env * 12000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_diamond_sound() {
	if 'diamond' in sm.clips {
		sm.play_clip('diamond')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 100
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := if i < num_samples / 2 { 1760.0 } else { 2349.32 }
		env := math.exp(-25.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 15000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_impact_sound() {
	if 'boulder' in sm.clips {
		sm.play_clip('boulder')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 120.0 - (70.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-30.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_explosion_sound() {
	if 'explode' in sm.clips {
		sm.play_clip('explode')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		freq := 140.0 - (100.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-8.0 * t)
		sample := (math.sin(2.0 * math.pi * freq * t) * 0.4 + noise * 0.6) * env * 22000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_door_open_sound() {
	if 'door' in sm.clips {
		sm.play_clip('door')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 587.33 + (400.0 * math.sin(25.0 * math.pi * t))
		env := math.exp(-6.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 16000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_death_sound() {
	if 'die' in sm.clips {
		sm.play_clip('die')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 350
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0 - (320.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-6.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 17000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_win_sound() {
	if 'win' in sm.clips {
		sm.play_clip('win')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 550
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	note_len := num_samples / notes.len

	for i in 0 .. num_samples {
		note_idx := i / note_len
		freq := notes[note_idx]
		t_note := f64(i % note_len) / f64(sample_rate)
		env := math.exp(-8.0 * t_note)
		sample := math.sin(2.0 * math.pi * freq * t_note) * env * 18000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}
