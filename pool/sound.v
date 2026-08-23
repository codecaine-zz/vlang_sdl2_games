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
	sm.init()
	sm.load_all_clips()
	return sm
}

pub fn (mut sm SoundManager) init() {
	if sm.dev_id != 0 {
		return
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
}

fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/sounds/${filename}',
		'assets/music/${filename}',
		'pool/assets/sounds/${filename}',
		'pool/assets/music/${filename}',
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
	sm.load_clip('bgm', 'pool_bgm.wav')
	sm.load_clip('strike', 'pool_strike.wav')
	sm.load_clip('ball_hit', 'pool_ball_hit.wav')
	sm.load_clip('cushion', 'pool_cushion.wav')
	sm.load_clip('pot', 'pool_pot.wav')
	sm.load_clip('break', 'pool_break.wav')
	sm.load_clip('win', 'pool_win.wav')
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
	if !sm.enabled || samples.len == 0 {
		return
	}
	if sm.dev_id == 0 {
		sm.init()
		if sm.dev_id == 0 {
			return
		}
	}
	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued > u32(audio_sample_rate * int(sizeof(i16)) / 4) {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

// Sharp leather cue tip tap and wood shaft resonance
pub fn (mut sm SoundManager) play_cue_strike(power f64) {
	if sm.play_clip('strike') {
		return
	}
	dur := 0.12
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	vol := math.clamp(0.4 + power * 0.6, 0.3, 1.0)

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		tone := math.sin(2.0 * math.pi * 1200.0 * t) * math.exp(-35.0 * t)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-40.0 * t) * 0.8
		sample := (tone * 0.6 + noise * 0.5) * vol
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// High-pitch phenolic resin ball crack
pub fn (mut sm SoundManager) play_ball_collision(intensity f64) {
	if sm.play_clip('ball_hit') {
		return
	}
	dur := 0.09
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	vol := math.clamp(0.3 + intensity * 0.7, 0.2, 1.0)

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		freq := 2800.0 + intensity * 600.0
		tone := math.sin(2.0 * math.pi * freq * t) * math.exp(-45.0 * t)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-50.0 * t) * 0.4
		sample := (tone * 0.8 + noise * 0.4) * vol
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Low rubber rail thud
pub fn (mut sm SoundManager) play_cushion_hit(intensity f64) {
	if sm.play_clip('cushion') {
		return
	}
	dur := 0.10
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	vol := math.clamp(0.25 + intensity * 0.5, 0.2, 0.8)

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		tone := math.sin(2.0 * math.pi * 180.0 * t) * math.exp(-22.0 * t)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-25.0 * t) * 0.5
		sample := (tone * 0.7 + noise * 0.4) * vol
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Leather pocket drop
pub fn (mut sm SoundManager) play_pocket_drop() {
	if sm.play_clip('pot') {
		return
	}
	dur := 0.25
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		rattle := math.sin(2.0 * math.pi * 320.0 * t) * math.exp(-12.0 * t)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-15.0 * t) * 0.6
		sample := (rattle * 0.6 + noise * 0.5) * 0.8
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Scratch slide
pub fn (mut sm SoundManager) play_scratch() {
	dur := 0.40
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		freq := math.max(100.0, 300.0 - t * 250.0)
		sample := math.sin(2.0 * math.pi * freq * t) * math.exp(-4.0 * t) * 0.7
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Victory fanfare
pub fn (mut sm SoundManager) play_victory() {
	if sm.play_clip('win') {
		return
	}
	dur := 0.85
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		step := int(t * 7.0) % 4
		freq := match step {
			0 { 523.25 } // C5
			1 { 659.25 } // E5
			2 { 783.99 } // G5
			else { 1046.5 } // C6
		}
		decay := 1.0 - (t / dur) * 0.3
		sample := math.sin(2.0 * math.pi * freq * t) * decay * 0.6
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}
