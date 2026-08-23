module main

import math
import os
import rand
import sdl

const audio_sample_rate = 44100

struct SoundClip {
mut:
	buf &u8 = &u8(unsafe { nil })
	len u32
}

pub struct SoundManager {
pub mut:
	dev_id  u32
	enabled bool = true
	clips   map[string]SoundClip
}

pub fn new_sound_manager() SoundManager {
	mut sm := SoundManager{
		enabled: true
	}
	if sdl.was_init(sdl.init_audio) == 0 {
		sdl.init_sub_system(sdl.init_audio)
	}
	spec := sdl.AudioSpec{
		freq:     audio_sample_rate
		format:   sdl.AudioFormat(sdl.audio_s16sys)
		channels: 1
		samples:  1024
		callback: unsafe { nil }
	}
	obtained := sdl.AudioSpec{}
	dev := sdl.open_audio_device(unsafe { nil }, 0, &spec, &obtained, 0)
	if dev > 0 {
		sm.dev_id = dev
		sdl.pause_audio_device(dev, 0)
	}
	sm.load_all_clips()
	return sm
}

fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/sounds/${filename}',
		'assets/music/${filename}',
		'airhockey/assets/sounds/${filename}',
		'airhockey/assets/music/${filename}',
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
	sm.load_clip('bgm', 'airhockey_bgm.wav')
	sm.load_clip('hit', 'airhockey_hit.wav')
	sm.load_clip('wall', 'airhockey_wall.wav')
	sm.load_clip('goal', 'airhockey_goal.wav')
	sm.load_clip('win', 'airhockey_win.wav')
}

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.enabled = !sm.enabled
	if !sm.enabled && sm.dev_id != 0 {
		sdl.clear_queued_audio(sm.dev_id)
	}
	return sm.enabled
}

pub fn (mut sm SoundManager) update_bgm(is_active bool) {
	if !sm.enabled || sm.dev_id == 0 || !is_active {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued < 8192 {
		sm.play_clip('bgm')
	}
}

fn (mut sm SoundManager) play_clip(name string) bool {
	if !sm.enabled || sm.dev_id == 0 {
		return false
	}
	if clip := sm.clips[name] {
		if clip.len > 0 && !isnil(clip.buf) {
			sdl.queue_audio(sm.dev_id, clip.buf, clip.len)
			return true
		}
	}
	return false
}

fn (mut sm SoundManager) play_samples(samples []i16) {
	if !sm.enabled || sm.dev_id == 0 || samples.len == 0 {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued > u32(audio_sample_rate * int(sizeof(i16)) / 4) {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

// Sharp mallet hit clack
pub fn (mut sm SoundManager) play_mallet_hit(speed f64) {
	if sm.play_clip('hit') {
		return
	}
	dur := 0.08
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	vol := math.clamp(speed / 400.0, 0.4, 1.0)

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 50.0)
		s := (math.sin(t * 850.0 * 2.0 * math.pi) + (rand.f64() * 2.0 - 1.0) * 0.3) * env * 24000.0 * vol
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Soft rail bounce
pub fn (mut sm SoundManager) play_rail_bounce(speed f64) {
	if sm.play_clip('wall') {
		return
	}
	dur := 0.06
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	vol := math.clamp(speed / 400.0, 0.3, 0.9)

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 60.0)
		s := math.sin(t * 420.0 * 2.0 * math.pi) * env * 18000.0 * vol
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Goal Horn Siren
pub fn (mut sm SoundManager) play_goal_horn() {
	if sm.play_clip('goal') {
		return
	}
	dur := 0.8
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := if t < 0.1 { t / 0.1 } else { math.exp(-(t - 0.1) * 3.0) }
		f1 := 293.66 // D4
		f2 := 349.23 // F4
		f3 := 440.00 // A4
		s := (math.sin(t * f1 * 2.0 * math.pi) + math.sin(t * f2 * 2.0 * math.pi) + 0.8 * math.sin(t * f3 * 2.0 * math.pi)) / 3.0
		val := s * env * 24000.0
		samples << i16(math.clamp(val, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Game victory fanfare
pub fn (mut sm SoundManager) play_victory() {
	if sm.play_clip('win') {
		return
	}
	dur := 0.9
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := if t < 0.2 { 523.25 } else if t < 0.4 { 659.25 } else if t < 0.6 { 783.99 } else { 1046.50 }
		env := math.exp(-math.fmod(t, 0.2) * 8.0)
		s := math.sin(t * freq * 2.0 * math.pi) * env * 20000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}
