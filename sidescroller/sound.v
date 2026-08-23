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
		'sidescroller/assets/sounds/${filename}',
		'sidescroller/assets/music/${filename}',
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
	sm.load_clip('bgm', 'sidescroller_bgm.wav')
	sm.load_clip('laser', 'sidescroller_laser.wav')
	sm.load_clip('spread', 'sidescroller_spread.wav')
	sm.load_clip('plasma', 'sidescroller_plasma.wav')
	sm.load_clip('missile', 'sidescroller_missile.wav')
	sm.load_clip('beam', 'sidescroller_beam.wav')
	sm.load_clip('explode_sm', 'sidescroller_explode_sm.wav')
	sm.load_clip('explode_lg', 'sidescroller_explode_lg.wav')
	sm.load_clip('powerup', 'sidescroller_powerup.wav')
	sm.load_clip('dash', 'sidescroller_dash.wav')
	sm.load_clip('jump', 'sidescroller_jump.wav')
	sm.load_clip('boss', 'sidescroller_boss_alert.wav')
	sm.load_clip('victory', 'sidescroller_victory.wav')
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

fn (sm &SoundManager) play_sound_raw(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

fn (sm &SoundManager) play_laser() {
	if sm.play_clip('laser') {
		return
	}
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 900.0 - (t * 8000.0)
		env := 1.0 - (f64(i) / f64(num_samples))
		val := math.sin(2.0 * math.pi * math.max(100.0, freq) * t) * env * 0.4
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_spread() {
	if sm.play_clip('spread') {
		return
	}
	sample_rate := 44100
	duration_ms := 100
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0 - (t * 2000.0)
		noise := (rand.f64() * 2.0 - 1.0) * 0.3
		env := 1.0 - (f64(i) / f64(num_samples))
		val := (math.sin(2.0 * math.pi * math.max(80.0, freq) * t) * 0.5 + noise) * env * 0.4
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_plasma() {
	if sm.play_clip('plasma') {
		return
	}
	sample_rate := 44100
	duration_ms := 140
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1200.0 + math.sin(t * 120.0) * 400.0
		env := math.exp(-12.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 0.5
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_missile() {
	if sm.play_clip('missile') {
		return
	}
	sample_rate := 44100
	duration_ms := 150
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 300.0 + (t * 1200.0)
		noise := (rand.f64() * 2.0 - 1.0) * 0.4
		env := 1.0 - (f64(i) / f64(num_samples))
		val := (math.sin(2.0 * math.pi * freq * t) * 0.6 + noise) * env * 0.45
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_beam() {
	if sm.play_clip('beam') {
		return
	}
	sample_rate := 44100
	duration_ms := 200
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 800.0 + math.sin(t * 200.0) * 200.0
		val := (if math.sin(2.0 * math.pi * freq * t) > 0.0 { 0.4 } else { -0.4 })
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_explosion_small() {
	if sm.play_clip('explode_sm') {
		return
	}
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		env := math.exp(-15.0 * t)
		val := noise * env * 0.5
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_explosion_large() {
	if sm.play_clip('explode_lg') {
		return
	}
	sample_rate := 44100
	duration_ms := 400
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 120.0 - (t * 80.0)
		noise := (rand.f64() * 2.0 - 1.0) * 0.6
		env := math.exp(-6.0 * t)
		val := (math.sin(2.0 * math.pi * math.max(30.0, freq) * t) * 0.4 + noise) * env * 0.6
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_jump() {
	if sm.play_clip('jump') {
		return
	}
	sample_rate := 44100
	duration_ms := 100
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 250.0 + (t * 600.0)
		env := 1.0 - (f64(i) / f64(num_samples))
		val := math.sin(2.0 * math.pi * freq * t) * env * 0.35
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_dash() {
	if sm.play_clip('dash') {
		return
	}
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * 0.5
		freq := 400.0 - (t * 300.0)
		env := math.exp(-12.0 * t)
		val := (math.sin(2.0 * math.pi * freq * t) * 0.3 + noise) * env * 0.4
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_powerup() {
	if sm.play_clip('powerup') {
		return
	}
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 440.0 + (t * 1200.0)
		env := 1.0 - (f64(i) / f64(num_samples))
		val := math.sin(2.0 * math.pi * freq * t) * env * 0.4
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_boss_alert() {
	if sm.play_clip('boss') {
		return
	}
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 220.0 + math.sin(t * 40.0) * 60.0
		val := math.sin(2.0 * math.pi * freq * t) * 0.4
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_victory() {
	if sm.play_clip('victory') {
		return
	}
	sample_rate := 44100
	duration_ms := 500
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_len := num_samples / notes.len
	for i in 0 .. num_samples {
		note_idx := i / note_len
		freq := notes[note_idx]
		t_note := f64(i % note_len) / f64(sample_rate)
		env := 1.0 - (f64(i % note_len) / f64(note_len))
		val := math.sin(2.0 * math.pi * freq * t_note) * env * 0.4
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_explosion() {
	sm.play_explosion_large()
}

fn (sm &SoundManager) play_emp_bomb() {
	sm.play_explosion_large()
}

fn (sm &SoundManager) play_boss_siren() {
	sm.play_boss_alert()
}

fn (sm &SoundManager) play_flame() {
	sm.play_spread()
}

fn (sm &SoundManager) play_grenade() {
	sm.play_missile()
}

fn (sm &SoundManager) play_hyper_laser() {
	sm.play_beam()
}

fn (sm &SoundManager) play_tesla() {
	sm.play_laser()
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
