module main

import os
import math
import rand
import sdl

struct SoundClip {
mut:
	buf &u8 = &u8(unsafe { nil })
	len u32
}

struct SoundManager {
pub mut:
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
		'donkeykong/assets/sounds/${filename}',
		'donkeykong/assets/music/${filename}',
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
	sm.load_clip('bgm', 'donkeykong_bgm.wav')
	sm.load_clip('jump', 'donkeykong_jump.wav')
	sm.load_clip('walk', 'donkeykong_walk.wav')
	sm.load_clip('hammer', 'donkeykong_hammer.wav')
	sm.load_clip('barrel', 'donkeykong_barrel.wav')
	sm.load_clip('climb', 'donkeykong_climb.wav')
	sm.load_clip('roar', 'donkeykong_roar.wav')
	sm.load_clip('win', 'donkeykong_win.wav')
	sm.load_clip('die', 'donkeykong_die.wav')
}

fn (sm &SoundManager) play_clip(name string) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	if clip := sm.clips[name] {
		if clip.buf != unsafe { nil } && clip.len > 0 {
			sdl.queue_audio(sm.dev, clip.buf, clip.len)
			return
		}
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

fn (sm &SoundManager) update_bgm(is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 || !is_active {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev)
	if queued < 8192 {
		sm.play_clip('bgm')
	}
}

fn (sm &SoundManager) play_jump_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'jump' in sm.clips {
		sm.play_clip('jump')
		return
	}
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 300.0 + 500.0 * (f64(i) / f64(num_samples))
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		pcm[i] = i16(sq * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_hammer_pickup_sound() {
	sm.play_hammer_smash_sound()
}

fn (sm &SoundManager) play_hammer_smash_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'hammer' in sm.clips {
		sm.play_clip('hammer')
		return
	}
	sample_rate := 44100
	duration_ms := 150
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		sq := if math.sin(2.0 * math.pi * 500.0 * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-12.0 * t)
		pcm[i] = i16((noise * 0.5 + sq * 0.5) * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_victory_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'win' in sm.clips {
		sm.play_clip('win')
		return
	}
	sample_rate := 44100
	duration_ms := 400
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note := int(t * 10.0)
		freq := 400.0 + f64(note) * 100.0
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		pcm[i] = i16(sq * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}
