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
		'asteroids/assets/sounds/${filename}',
		'asteroids/assets/music/${filename}',
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
	sm.load_clip('bgm', 'asteroids_bgm.wav')
	sm.load_clip('laser', 'asteroids_shoot.wav')
	sm.load_clip('thrust', 'asteroids_thrust.wav')
	sm.load_clip('explosion', 'asteroids_explode_lg.wav')
	sm.load_clip('explosion_sm', 'asteroids_explode_sm.wav')
	sm.load_clip('ufo', 'asteroids_ufo_spawn.wav')
	sm.load_clip('ufo_fire', 'asteroids_ufo_fire.wav')
	sm.load_clip('powerup', 'asteroids_powerup.wav')
	sm.load_clip('shield', 'asteroids_shield.wav')
	sm.load_clip('hyperspace', 'asteroids_hyperspace.wav')
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

fn (sm &SoundManager) clear_audio() {
	if sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
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

fn (sm &SoundManager) play_shoot(is_plasma bool) {
	if sm.play_clip('laser') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := if is_plasma { 140 } else { 80 }
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := if is_plasma {
			900.0 - (700.0 * (f64(i) / f64(num_samples)))
		} else {
			1200.0 - (900.0 * (f64(i) / f64(num_samples)))
		}
		env := math.exp(-18.0 * t)
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		sample := sq * env * 14000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_thrust() {
	if sm.play_clip('thrust') {
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
		env := math.exp(-15.0 * t)
		sample := (noise * 0.7 + math.sin(2.0 * math.pi * 90.0 * t) * 0.3) * env * 12000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_explosion(is_big bool) {
	if is_big {
		if sm.play_clip('explosion') {
			return
		}
	} else {
		if sm.play_clip('explosion_sm') {
			return
		}
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := if is_big { 350 } else { 150 }
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		freq := if is_big {
			150.0 - (120.0 * (f64(i) / f64(num_samples)))
		} else {
			280.0 - (200.0 * (f64(i) / f64(num_samples)))
		}
		env := math.exp(-6.0 * t)
		sample := (math.sin(2.0 * math.pi * freq * t) * 0.4 + noise * 0.6) * env * 22000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_powerup() {
	if sm.play_clip('powerup') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	notes := [523.25, 659.25, 783.99, 1046.50]
	note_len := num_samples / notes.len

	for i in 0 .. num_samples {
		note_idx := i / note_len
		freq := notes[note_idx]
		t_note := f64(i % note_len) / f64(sample_rate)
		env := math.exp(-12.0 * t_note)
		sample := math.sin(2.0 * math.pi * freq * t_note) * env * 18000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_ufo_spawn() {
	if sm.play_clip('ufo') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 250
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 450.0 + (350.0 * math.sin(20.0 * math.pi * t))
		env := math.exp(-4.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 16000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_shield_hit() {
	if sm.play_clip('shield') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 300.0 + (600.0 * math.sin(30.0 * math.pi * t))
		env := math.exp(-12.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_hyperspace() {
	if sm.play_clip('hyperspace') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 280
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 200.0 + (900.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-5.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * env * 20000.0
		pcm[i] = i16(sample)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

fn (sm &SoundManager) play_laser_sound() {
	sm.play_shoot(false)
}

fn (sm &SoundManager) play_plasma_sound() {
	sm.play_shoot(true)
}

fn (sm &SoundManager) play_explosion_sound(param int) {
	sm.play_explosion(param != 0)
}

fn (sm &SoundManager) play_powerup_sound() {
	sm.play_powerup()
}

fn (sm &SoundManager) play_emp_sound() {
	sm.play_explosion(true)
}

fn (sm &SoundManager) play_warp_sound() {
	sm.play_hyperspace()
}

fn (sm &SoundManager) play_shield_sound() {
	sm.play_shield_hit()
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
