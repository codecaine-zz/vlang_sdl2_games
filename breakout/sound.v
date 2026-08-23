module main

import os
import math
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
		'../assets/sounds/${filename}',
		'../assets/music/${filename}',
		'/Users/codecaine/vland_sdl2_games/assets/sounds/${filename}',
		'/Users/codecaine/vland_sdl2_games/assets/music/${filename}'
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
	sm.load_clip('bounce', 'bounce.wav')
	sm.load_clip('hit', 'hit.wav')
	sm.load_clip('explosion', 'explosion.wav')
	sm.load_clip('laser', 'laser.wav')
	sm.load_clip('powerup', 'powerup.wav')
	sm.load_clip('win', 'win.wav')
	sm.load_clip('die', 'die.wav')
	sm.load_clip('bgm', 'breakout_bgm.wav')
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

fn (sm &SoundManager) play_pcm(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

fn (sm &SoundManager) play_paddle_hit() {
	if sm.play_clip('bounce') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 30
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 480.0
		env := math.exp(-35.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
		pcm[i] = i16(harm * env * attack * 20000.0)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_brick_hit(pitch f64) {
	if sm.play_clip('hit') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000
	base_freq := 320.0 + pitch * 150.0

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-28.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * base_freq * t) + 0.4 * math.sin(4.0 * math.pi * base_freq * t)
		pcm[i] = i16(harm * env * attack * 22000.0)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_metal_hit() {
	if sm.play_clip('bounce') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 30
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-40.0 * t)
		val := (math.sin(2.0 * math.pi * 900.0 * t) + 0.5 * math.sin(2.0 * math.pi * 1400.0 * t)) * env * 22000.0
		pcm[i] = i16(val)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_explosion_sound() {
	if sm.play_clip('explosion') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 90
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		f := 350.0 - (200.0 * (f64(i) / f64(num_samples)))
		noise := (rand.f64() * 2.0) - 1.0
		env := math.exp(-14.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		val := (math.sin(2.0 * math.pi * f * t) * 0.7 + noise * 0.3) * env * attack * 24000.0
		pcm[i] = i16(val)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_laser_sound() {
	if sm.play_clip('laser') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 980.0 - (700.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-22.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
		pcm[i] = i16(harm * env * attack * 20000.0)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_powerup_sound() {
	if sm.play_clip('powerup') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_dur := 35
	num_samples := (sample_rate * note_dur * notes.len) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	attack_samples := sample_rate * 2 / 1000

	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-12.0 * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
			pcm[sample_idx] = i16(harm * env * attack * 22000.0)
		}
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_lose_ball_sound() {
	if sm.play_clip('die') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 260
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0 - (300.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-8.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t)
		pcm[i] = i16(harm * env * attack * 22000.0)
	}
	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_win_fanfare() {
	if sm.play_clip('win') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	note_dur := 45
	num_samples := (sample_rate * note_dur * notes.len) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000

	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-8.0 * t)
			harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(2.0 * math.pi * freq * 2.0 * t)
			pcm[sample_idx] = i16(harm * env * 24000.0)
		}
	}
	sm.play_pcm(pcm)
}

fn (mut sm SoundManager) cleanup() {
	for _, clip in sm.clips {
		if !isnil(clip.buf) {
			sdl.free_wav(clip.buf)
		}
	}
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
		sm.dev = 0
	}
}
