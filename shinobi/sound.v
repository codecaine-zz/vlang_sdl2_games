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
		'shinobi/assets/sounds/${filename}',
		'shinobi/assets/music/${filename}',
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
	sm.load_clip('bgm', 'shinobi_bgm.wav')
	sm.load_clip('shuriken', 'shinobi_shuriken.wav')
	sm.load_clip('slash', 'shinobi_slash.wav')
	sm.load_clip('jump', 'shinobi_jump.wav')
	sm.load_clip('hit', 'shinobi_hit.wav')
	sm.load_clip('drone_shot', 'shinobi_drone_shot.wav')
	sm.load_clip('explode', 'shinobi_explode.wav')
	sm.load_clip('ninjutsu', 'shinobi_ninjutsu.wav')
	sm.load_clip('rescue', 'shinobi_rescue.wav')
	sm.load_clip('gameover', 'shinobi_gameover.wav')
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

fn (sm &SoundManager) play_slash_sound() {
	if sm.play_clip('slash') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 70
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1400.0 - 1000.0 * (f64(i) / f64(num_samples))
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-25.0 * t)
		pcm[i] = i16(sq * env * 15000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_shuriken_sound() {
	if sm.play_clip('shuriken') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 600.0 + 600.0 * (f64(i) / f64(num_samples))
		sine := math.sin(2.0 * math.pi * freq * t)
		pcm[i] = i16(sine * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_jump_sound() {
	if sm.play_clip('jump') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 70
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0 + 400.0 * (f64(i) / f64(num_samples))
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-20.0 * t)
		pcm[i] = i16(sq * env * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_explosion_sound() {
	if sm.play_clip('explode') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 200
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		env := math.exp(-10.0 * t)
		pcm[i] = i16(noise * env * 18000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
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
