module main

import math
import os
import rand
import sdl

pub struct SoundClip {
pub mut:
	buf &u8 = &u8(unsafe { nil })
	len u32
}

pub struct SoundManager {
pub mut:
	dev_id        u32
	sound_enabled bool = true
	clips         map[string]SoundClip
}

pub fn new_sound_manager() SoundManager {
	mut sm := SoundManager{
		sound_enabled: true
	}
	spec := sdl.AudioSpec{
		freq:     44100
		format:   sdl.AudioFormat(sdl.audio_s16lsb)
		channels: 1
		samples:  1024
	}
	obtained := sdl.AudioSpec{}
	sm.dev_id = sdl.open_audio_device(unsafe { nil }, 0, &spec, &obtained, 0)
	if sm.dev_id > 0 {
		sdl.pause_audio_device(sm.dev_id, 0)
	}

	sm.load_all_clips()
	return sm
}

pub fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/sounds/${filename}',
		'towerfall/assets/sounds/${filename}',
		'../assets/sounds/${filename}',
		'./assets/sounds/${filename}',
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

pub fn (mut sm SoundManager) load_all_clips() {
	sm.load_clip('bgm', 'towerfall_bgm.wav')
	sm.load_clip('shoot', 'towerfall_shoot.wav')
	sm.load_clip('hit', 'towerfall_hit.wav')
	sm.load_clip('dash', 'towerfall_dash.wav')
	sm.load_clip('catch', 'towerfall_catch.wav')
	sm.load_clip('explode', 'towerfall_explode.wav')
	sm.load_clip('death', 'towerfall_death.wav')
	sm.load_clip('win', 'towerfall_win.wav')
}

pub fn (mut sm SoundManager) update_bgm(active bool) {
	if !sm.sound_enabled || sm.dev_id == 0 || !active { return }
	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued < 8192 {
		clip := sm.clips['bgm'] or { return }
		if !isnil(clip.buf) && clip.len > 0 {
			sdl.queue_audio(sm.dev_id, clip.buf, clip.len)
		}
	}
}

pub fn (mut sm SoundManager) play_clip(name string) bool {
	if !sm.sound_enabled || sm.dev_id == 0 { return false }
	if name in sm.clips {
		clip := sm.clips[name] or { return false }
		if !isnil(clip.buf) && clip.len > 0 {
			sdl.clear_queued_audio(sm.dev_id)
			sdl.queue_audio(sm.dev_id, clip.buf, clip.len)
			return true
		}
	}
	return false
}

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.sound_enabled = !sm.sound_enabled
	return sm.sound_enabled
}

fn (mut sm SoundManager) play_samples(samples []i16) {
	if !sm.sound_enabled || sm.dev_id == 0 {
		return
	}
	sdl.clear_queued_audio(sm.dev_id)
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * 2))
}

// 1. Bow Shoot
pub fn (mut sm SoundManager) play_bow_shoot() {
	if sm.play_clip('shoot') { return }
	count := 44100 / 12
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := 480.0 - (t * 4000.0)
		env := math.max(0.0, 1.0 - (f64(i) / f64(count)))
		val := math.sin(2.0 * math.pi * math.max(60.0, freq) * t) * env
		samples << i16(val * 14000.0)
	}
	sm.play_samples(samples)
}

// 2. Arrow Hit Wall
pub fn (mut sm SoundManager) play_arrow_hit_wall() {
	if sm.play_clip('hit') { return }
	count := 44100 / 16
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := 240.0 * math.exp(-t * 25.0)
		env := math.max(0.0, 1.0 - (f64(i) / f64(count)))
		noise := (rand.f64() - 0.5) * 0.3
		val := (math.sin(2.0 * math.pi * freq * t) + noise) * env
		samples << i16(val * 16000.0)
	}
	sm.play_samples(samples)
}

// 3. Dodge Dash
pub fn (mut sm SoundManager) play_dodge_dash() {
	if sm.play_clip('dash') { return }
	count := 44100 / 10
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		env := math.sin(math.pi * (f64(i) / f64(count)))
		noise := (rand.f64() - 0.5) * env
		samples << i16(noise * 12000.0)
	}
	sm.play_samples(samples)
}

// 4. Arrow Catch
pub fn (mut sm SoundManager) play_arrow_catch() {
	if sm.play_clip('catch') { return }
	count := 44100 / 6
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := 880.0 + (t * 1200.0)
		env := math.max(0.0, 1.0 - (f64(i) / f64(count)))
		val := math.sin(2.0 * math.pi * freq * t) * env
		samples << i16(val * 18000.0)
	}
	sm.play_samples(samples)
}

// 5. Explosion
pub fn (mut sm SoundManager) play_explosion() {
	if sm.play_clip('explode') { return }
	count := 44100 / 4
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 6.0)
		noise := (rand.f64() - 0.5) * env
		samples << i16(noise * 22000.0)
	}
	sm.play_samples(samples)
}

// 6. Player Death
pub fn (mut sm SoundManager) play_player_death() {
	if sm.play_clip('death') { return }
	count := 44100 / 5
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := 320.0 - (t * 800.0)
		env := math.max(0.0, 1.0 - (f64(i) / f64(count)))
		val := math.sin(2.0 * math.pi * math.max(50.0, freq) * t) * env
		samples << i16(val * 20000.0)
	}
	sm.play_samples(samples)
}

// 7. Wave Clear
pub fn (mut sm SoundManager) play_wave_clear() {
	if sm.play_clip('win') { return }
	count := 44100 / 3
	mut samples := []i16{cap: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		step := int(t * 12.0)
		note := match step % 3 {
			0 { 523.25 }
			1 { 659.25 }
			else { 783.99 }
		}
		env := math.max(0.0, 1.0 - (f64(i) / f64(count)))
		val := math.sin(2.0 * math.pi * note * t) * env
		samples << i16(val * 16000.0)
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) cleanup() {
	if sm.dev_id > 0 {
		sdl.close_audio_device(sm.dev_id)
		sm.dev_id = 0
	}
}
