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
		'slots/assets/sounds/${filename}',
		'slots/assets/music/${filename}',
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
	sm.load_clip('bgm', 'slots_bgm.wav')
	sm.load_clip('lever', 'slots_lever.wav')
	sm.load_clip('spin', 'slots_spin.wav')
	sm.load_clip('stop', 'slots_stop.wav')
	sm.load_clip('win', 'slots_win.wav')
	sm.load_clip('jackpot', 'slots_jackpot.wav')
	sm.load_clip('lose', 'slots_lose.wav')
	sm.load_clip('hold', 'slots_hold.wav')
	sm.load_clip('coin', 'slots_coin.wav')
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

// Mechanical one-armed bandit lever ratchet pull
pub fn (mut sm SoundManager) play_lever_pull() {
	if sm.play_clip('lever') {
		return
	}
	dur := 0.20
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		tick_pulse := if int(t * 70.0) % 2 == 0 { 0.5 } else { -0.5 }
		spring := math.sin(2.0 * math.pi * 320.0 * t) * math.exp(-15.0 * t)
		sample := (tick_pulse * 0.4 + spring * 0.6) * 0.7
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Reel whirr sound during spinning
pub fn (mut sm SoundManager) play_reel_spin() {
	if sm.play_clip('spin') {
		return
	}
	dur := 0.14
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * 0.3
		hum := math.sin(2.0 * math.pi * 180.0 * t) * 0.5
		sample := (noise + hum) * 0.35
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Solid mechanical solenoid reel lock/click stop
pub fn (mut sm SoundManager) play_reel_stop(reel_idx int) {
	if sm.play_clip('stop') {
		return
	}
	dur := 0.08
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	pitch := 380.0 + f64(reel_idx) * 60.0

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		tone := math.sin(2.0 * math.pi * pitch * t) * math.exp(-45.0 * t)
		click := (rand.f64() * 2.0 - 1.0) * math.exp(-60.0 * t) * 0.7
		sample := (tone * 0.6 + click * 0.5) * 0.8
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Metallic coins clinking cascade
pub fn (mut sm SoundManager) play_coin_payout() {
	if sm.play_clip('coin') {
		return
	}
	dur := 0.30
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		step := int(t * 22.0)
		f := 2000.0 + f64((step * 347) % 1800)
		ping := math.sin(2.0 * math.pi * f * t) * math.exp(-math.fmod(t * 22.0, 1.0) * 20.0)
		sample := ping * 0.6
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Winning payline chord chime
pub fn (mut sm SoundManager) play_win_chime() {
	if sm.play_clip('win') {
		return
	}
	dur := 0.45
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		step := int(t * 10.0) % 3
		freq := match step {
			0 { 659.25 } // E5
			1 { 830.61 } // G#5
			else { 987.77 } // B5
		}
		decay := math.exp(-5.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * decay * 0.65
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Mega Jackpot / Free Spins Fanfare
pub fn (mut sm SoundManager) play_jackpot_fanfare() {
	if sm.play_clip('jackpot') {
		return
	}
	dur := 1.20
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		step := int(t * 7.0) % 5
		freq := match step {
			0 { 523.25 } // C5
			1 { 659.25 } // E5
			2 { 783.99 } // G5
			3 { 1046.50 } // C6
			else { 1318.51 } // E6
		}
		decay := 1.0 - (t / dur) * 0.3
		sample := math.sin(2.0 * math.pi * freq * t) * decay * 0.75
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Disappointed negative loss buzzer / descending chord
pub fn (mut sm SoundManager) play_lose_sound() {
	if sm.play_clip('lose') {
		return
	}
	dur := 0.45
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		step := int(t * 7.0) % 3
		freq := match step {
			0 { 293.66 } // D4
			1 { 261.63 } // C4
			else { 220.00 } // A3
		}
		saw := (math.sin(2.0 * math.pi * freq * t) * 0.6 +
			math.sin(4.0 * math.pi * freq * t) * 0.3 +
			math.sin(6.0 * math.pi * freq * t) * 0.15)
		wobble := 1.0 + 0.15 * math.sin(2.0 * math.pi * 12.0 * t)
		sample := saw * wobble * math.exp(-t * 6.0) * 0.75
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}
