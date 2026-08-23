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
		'zuma/assets/sounds/${filename}',
		'zuma/assets/music/${filename}',
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
	sm.load_clip('bgm', 'zuma_bgm.wav')
	sm.load_clip('shoot', 'zuma_fire.wav')
	sm.load_clip('match', 'zuma_match.wav')
	sm.load_clip('combo', 'zuma_combo.wav')
	sm.load_clip('bomb', 'zuma_bomb.wav')
	sm.load_clip('slow', 'zuma_slow.wav')
	sm.load_clip('reverse', 'zuma_reverse.wav')
	sm.load_clip('skull', 'zuma_skull.wav')
	sm.load_clip('win', 'zuma_win.wav')
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

// Shoot marble thwack
fn (sm &SoundManager) play_shoot_sound() {
	if 'shoot' in sm.clips {
		sm.play_clip('shoot')
		return
	}
	sample_rate := 44100
	duration_ms := 55
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 680.0 - t * 6500.0
		if freq < 80.0 {
			continue
		}
		env := math.exp(-t * 30.0)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 17000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Ball insertion clack
fn (sm &SoundManager) play_insert_sound() {
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 420.0 + (1.0 - t * 25.0) * 200.0
		env := math.exp(-t * 40.0)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 15000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_swap_sound() {
	sm.play_insert_sound()
}

// Match 3+ explosion & chain chime
fn (sm &SoundManager) play_match_sound(combo int) {
	if combo > 1 && 'combo' in sm.clips {
		sm.play_clip('combo')
		return
	} else if 'match' in sm.clips {
		sm.play_clip('match')
		return
	}

	sample_rate := 44100
	duration_ms := 180 + combo * 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	base_freq := 440.0 * math.pow(1.1892, f64(combo - 1))

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-t * 10.0)
		s1 := math.sin(2.0 * math.pi * base_freq * t)
		s2 := math.sin(2.0 * math.pi * base_freq * 1.5 * t) * 0.6
		sample := (s1 + s2) * env * 15000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}

// Powerup activation
fn (sm &SoundManager) play_powerup_sound(pt PowerupType) {
	match pt {
		.bomb {
			if 'bomb' in sm.clips {
				sm.play_clip('bomb')
				return
			}
		}
		.slow {
			if 'slow' in sm.clips {
				sm.play_clip('slow')
				return
			}
		}
		.reverse {
			if 'reverse' in sm.clips {
				sm.play_clip('reverse')
				return
			}
		}
		else {}
	}
}

// Game Over skull swallow roar
fn (sm &SoundManager) play_skull_sound() {
	if 'skull' in sm.clips {
		sm.play_clip('skull')
		return
	}
	sample_rate := 44100
	duration_ms := 550
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 180.0 - t * 240.0
		if freq < 30.0 {
			continue
		}
		env := math.exp(-t * 4.0)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		pcm[i] = i16(sample)
	}
	sm.play_pcm(pcm)
}
