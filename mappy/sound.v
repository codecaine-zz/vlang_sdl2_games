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
		'mappy/assets/sounds/${filename}',
		'mappy/assets/music/${filename}',
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
	sm.load_clip('bgm', 'mappy_bgm.wav')
	sm.load_clip('bounce', 'mappy_bounce.wav')
	sm.load_clip('door', 'mappy_door.wav')
	sm.load_clip('loot', 'mappy_loot.wav')
	sm.load_clip('coin', 'mappy_coin.wav')
	sm.load_clip('stun', 'mappy_stun.wav')
	sm.load_clip('bonus', 'mappy_bonus.wav')
	sm.load_clip('die', 'mappy_die.wav')
	sm.load_clip('round', 'mappy_round.wav')
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

fn (sm &SoundManager) play_sound_raw(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

// Trampoline Boing sound
fn (sm &SoundManager) play_bounce() {
	if 'bounce' in sm.clips {
		sm.play_clip('bounce')
		return
	}
	sample_rate := 44100
	duration_ms := 90
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 180.0 + (t * 2200.0) + math.sin(t * 120.0) * 80.0
		env := 1.0 - (f64(i) / f64(num_samples))
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 14000.0)
	}
	sm.play_sound_raw(pcm)
}

// Door slam & Microwave wave sound
fn (sm &SoundManager) play_door_open() {
	if 'door' in sm.clips {
		sm.play_clip('door')
		return
	}
	sample_rate := 44100
	duration_ms := 140
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 800.0 - (t * 4000.0)
		env := math.exp(-t * 22.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 18000.0)
	}
	sm.play_sound_raw(pcm)
}

// Item / Loot Pickup sound
fn (sm &SoundManager) play_pickup() {
	if 'loot' in sm.clips {
		sm.play_clip('loot')
		return
	}
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 950.0 + (t * 2000.0)
		env := math.exp(-t * 25.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 15000.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_item_pickup(_ int) {
	sm.play_pickup()
}

fn (sm &SoundManager) play_hurry_up() {
	sm.play_stun()
}

fn (sm &SoundManager) play_gosenzo_appear() {
	sm.play_stun()
}

fn (sm &SoundManager) play_goro_reveal() {
	sm.play_coin()
}

fn (sm &SoundManager) play_microwave_wave() {
	sm.play_door_open()
}

fn (sm &SoundManager) play_door_stun() {
	sm.play_stun()
}

fn (sm &SoundManager) play_balloon_pop() {
	if 'bonus' in sm.clips {
		sm.play_clip('bonus')
		return
	}
	sm.play_coin()
}

fn (sm &SoundManager) play_bonus_perfect() {
	sm.play_stage_clear()
}

// Coin / Point sound
fn (sm &SoundManager) play_coin() {
	if 'coin' in sm.clips {
		sm.play_clip('coin')
		return
	}
	sm.play_pickup()
}

// Enemy Stunned sound
fn (sm &SoundManager) play_stun() {
	if 'stun' in sm.clips {
		sm.play_clip('stun')
		return
	}
	sample_rate := 44100
	duration_ms := 250
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1200.0 + math.sin(t * 80.0) * 300.0
		env := math.exp(-t * 10.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 12000.0)
	}
	sm.play_sound_raw(pcm)
}

// Player Death sound
fn (sm &SoundManager) play_death() {
	if 'die' in sm.clips {
		sm.play_clip('die')
		return
	}
	sample_rate := 44100
	duration_ms := 450
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 600.0 - (t * 900.0)
		env := math.exp(-t * 6.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 16000.0)
	}
	sm.play_sound_raw(pcm)
}

// Round Clear Fanfare
fn (sm &SoundManager) play_stage_clear() {
	if 'round' in sm.clips {
		sm.play_clip('round')
		return
	}
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_dur := 140
	samples_per_note := (sample_rate * note_dur) / 1000
	total_samples := samples_per_note * notes.len
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		st := n_idx * samples_per_note
		for i in 0 .. samples_per_note {
			t := f64(i) / f64(sample_rate)
			env := math.exp(-t * 10.0)
			pcm[st + i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 14000.0)
		}
	}
	sm.play_sound_raw(pcm)
}
