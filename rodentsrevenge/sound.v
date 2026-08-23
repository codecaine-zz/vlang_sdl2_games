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
		'rodentsrevenge/assets/sounds/${filename}',
		'rodentsrevenge/assets/music/${filename}',
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
	sm.load_clip('bgm', 'rodentsrevenge_bgm.wav')
	sm.load_clip('step', 'rodentsrevenge_step.wav')
	sm.load_clip('push', 'rodentsrevenge_push.wav')
	sm.load_clip('cheese', 'rodentsrevenge_cheese.wav')
	sm.load_clip('eat', 'rodentsrevenge_eat.wav')
	sm.load_clip('trap', 'rodentsrevenge_trap.wav')
	sm.load_clip('meow', 'rodentsrevenge_meow.wav')
	sm.load_clip('win', 'rodentsrevenge_win.wav')
	sm.load_clip('die', 'rodentsrevenge_gameover.wav')
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
	if queued > u32(audio_sample_rate * int(sizeof(i16)) / 3) {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

// Mouse Step Click
pub fn (mut sm SoundManager) play_step() {
	if sm.play_clip('step') { return }
	dur := 0.03
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 90.0)
		s := math.sin(2.0 * math.pi * 650.0 * t)
		val := i16(s * env * 11000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Block Push Thud
pub fn (mut sm SoundManager) play_push() {
	if sm.play_clip('push') { return }
	dur := 0.06
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 40.0)
		s := math.sin(2.0 * math.pi * 180.0 * t)
		val := i16(s * env * 14000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Cat Transformed into Cheese!
pub fn (mut sm SoundManager) play_cheese_spawn() {
	if sm.play_clip('cheese') { return }
	dur := 0.22
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	notes := [523.25, 659.25, 783.99]

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		n_idx := int(t / (dur / 3.0))
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		local_t := math.fmod(t, dur / 3.0)
		env := math.exp(-local_t * 18.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 14000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Eating Cheese Crunch
pub fn (mut sm SoundManager) play_eat() {
	if sm.play_clip('eat') { return }
	dur := 0.12
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 25.0)
		s := math.sin(2.0 * math.pi * 880.0 * t)
		noise := (rand.f64() * 2.0 - 1.0) * 0.4
		val := i16((s + noise) * env * 15000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Mousetrap Snap
pub fn (mut sm SoundManager) play_trap() {
	if sm.play_clip('trap') { return }
	sm.play_die()
}

// Cat Meow / Trapped
pub fn (mut sm SoundManager) play_meow() {
	if sm.play_clip('meow') { return }
}

// Level Win
pub fn (mut sm SoundManager) play_win() {
	if sm.play_clip('win') { return }
}

// Mouse Caught Squeak / Game Over
pub fn (mut sm SoundManager) play_die() {
	if sm.play_clip('die') { return }
	dur := 0.25
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 1200.0 * math.exp(-t * 10.0)
		env := math.exp(-t * 12.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 16000.0)
		samples << val
	}
	sm.play_samples(samples)
}
