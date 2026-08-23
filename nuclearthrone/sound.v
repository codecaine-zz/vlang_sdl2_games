module main

import os
import sdl

struct SoundClip {
mut:
	buf &u8 = &u8(unsafe { nil })
	len u32
}

pub struct SoundManager {
pub mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
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

fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/sounds/${filename}',
		'nuclearthrone/assets/sounds/${filename}',
		'../assets/sounds/${filename}',
		os.join_path('assets', 'sounds', filename),
		os.join_path('nuclearthrone', 'assets', 'sounds', filename),
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
	sm.load_clip('shoot', 'nuclearthrone_shoot.wav')
	sm.load_clip('laser', 'nuclearthrone_laser.wav')
	sm.load_clip('explosion', 'nuclearthrone_explosion.wav')
	sm.load_clip('rad', 'nuclearthrone_rad.wav')
	sm.load_clip('hit', 'nuclearthrone_hit.wav')
}

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.sound_enabled = !sm.sound_enabled
	if !sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return sm.sound_enabled
}

pub fn (mut sm SoundManager) play_sound(name string) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	if clip := sm.clips[name] {
		if clip.len > 0 && !isnil(clip.buf) {
			sdl.queue_audio(sm.dev, clip.buf, clip.len)
		}
	}
}

pub fn (mut sm SoundManager) update_bgm(active bool) {
	// Background audio loop hook
}
