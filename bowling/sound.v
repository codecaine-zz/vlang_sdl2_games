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
		'bowling/assets/sounds/${filename}',
		'bowling/assets/music/${filename}',
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
	sm.load_clip('bgm', 'bowling_bgm.wav')
	sm.load_clip('roll', 'bowling_roll.wav')
	sm.load_clip('strike', 'bowling_strike.wav')
	sm.load_clip('hit', 'bowling_hit.wav')
	sm.load_clip('gutter', 'bowling_gutter.wav')
	sm.load_clip('pinsetter', 'bowling_pinsetter.wav')
	sm.load_clip('cheer', 'bowling_cheer.wav')
	sm.load_clip('foul', 'bowling_foul.wav')
	sm.load_clip('win', 'bowling_win.wav')
}

pub fn (sm &SoundManager) play_clip(name string) {
	if !sm.enabled || sm.dev_id == 0 {
		return
	}
	if clip := sm.clips[name] {
		if clip.buf != unsafe { nil } && clip.len > 0 {
			sdl.queue_audio(sm.dev_id, clip.buf, clip.len)
		}
	}
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

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.enabled = !sm.enabled
	if !sm.enabled && sm.dev_id != 0 {
		sdl.clear_queued_audio(sm.dev_id)
	}
	return sm.enabled
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

// Low wood lane rumble as heavy bowling ball rolls down lane
pub fn (mut sm SoundManager) play_roll_sound(power f64) {
	if 'roll' in sm.clips {
		sm.play_clip('roll')
		return
	}
	dur := 1.2
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	vol := math.clamp(0.4 + power * 0.5, 0.2, 1.0)

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * 0.4
		rumble := math.sin(2.0 * math.pi * 65.0 * t) * 0.6
		sample := (noise + rumble) * vol * math.min(1.0, t * 4.0) * math.max(0.0, 1.0 - t / dur)
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Explosive maple wood pin-pin and ball-pin crash
pub fn (mut sm SoundManager) play_pin_hit(intensity f64) {
	if 'hit' in sm.clips {
		sm.play_clip('hit')
		return
	}
	dur := 0.22
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	vol := math.clamp(0.4 + intensity * 0.6, 0.2, 1.0)

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-35.0 * t) * 0.7
		tone1 := math.sin(2.0 * math.pi * 950.0 * t) * math.exp(-40.0 * t) * 0.5
		tone2 := math.sin(2.0 * math.pi * 1450.0 * t) * math.exp(-45.0 * t) * 0.4
		sample := (noise + tone1 + tone2) * vol
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Full house strike thunderous boom
pub fn (mut sm SoundManager) play_strike_sound() {
	if 'strike' in sm.clips {
		sm.play_clip('strike')
		return
	}
	dur := 0.6
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-12.0 * t) * 0.8
		bass := math.sin(2.0 * math.pi * 85.0 * t) * math.exp(-8.0 * t) * 0.6
		sample := (noise + bass) * 0.9
		samples << i16(sample * 24000.0)
	}
	sm.play_samples(samples)
}

// Gutter ball thud drop
pub fn (mut sm SoundManager) play_gutter_sound() {
	if 'gutter' in sm.clips {
		sm.play_clip('gutter')
		return
	}
	dur := 0.3
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-20.0 * t) * 0.6
		thud := math.sin(2.0 * math.pi * 90.0 * t) * math.exp(-25.0 * t) * 0.7
		sample := (noise + thud) * 0.7
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Mechanical pinsetter bar sweeping down lane
pub fn (mut sm SoundManager) play_pinsetter_sweep() {
	if 'pinsetter' in sm.clips {
		sm.play_clip('pinsetter')
		return
	}
	dur := 0.4
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		hum := math.sin(2.0 * math.pi * 120.0 * t) * 0.3
		gear := math.sin(2.0 * math.pi * 380.0 * t) * 0.2
		sample := (hum + gear) * 0.6
		samples << i16(sample * 12000.0)
	}
	sm.play_samples(samples)
}

// Crowd cheer applause
pub fn (mut sm SoundManager) play_cheer_sound() {
	if 'cheer' in sm.clips {
		sm.play_clip('cheer')
		return
	}
	dur := 1.0
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		clap := (rand.f64() * 2.0 - 1.0) * math.sin(t * math.pi) * 0.5
		samples << i16(clap * 14000.0)
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_strike_fanfare() {
	if 'win' in sm.clips {
		sm.play_clip('win')
		return
	}
	sm.play_cheer_sound()
}

pub fn (mut sm SoundManager) play_spare_fanfare() {
	if 'cheer' in sm.clips {
		sm.play_clip('cheer')
		return
	}
	sm.play_cheer_sound()
}
