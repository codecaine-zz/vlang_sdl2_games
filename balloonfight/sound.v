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
	bgm_step      int
	bgm_phase     f64
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
		'assets/music/${filename}',
		'assets/sounds/${filename}',
		'../assets/music/${filename}',
		'../assets/sounds/${filename}',
		os.join_path('assets', 'music', filename),
		os.join_path('assets', 'sounds', filename),
		os.join_path('..', 'assets', 'music', filename),
		os.join_path('..', 'assets', 'sounds', filename),
		os.join_path('balloonfight', 'assets', 'music', filename),
		os.join_path('balloonfight', 'assets', 'sounds', filename),
		'/Users/codecaine/vlang_sdl2_games/assets/music/${filename}',
		'/Users/codecaine/vlang_sdl2_games/assets/sounds/${filename}',
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
	sm.load_clip('bgm', 'balloonfight_bgm.wav')
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

fn (sm &SoundManager) update_bgm(is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 || !is_active {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev)
	if queued > 16384 {
		return
	}
	if sm.play_clip('bgm') {
		return
	}

	// Procedural 142 BPM Balloon Fight synth fallback
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	step_dur := 0.105 // 16th note at ~142 BPM
	samples_per_step := int(f64(sample_rate) * step_dur)
	mut pcm := []i16{len: samples_per_step}

	melody := [
		523.25, 659.25, 783.99, 1046.50, 987.77, 783.99, 659.25, 783.99,
		880.00, 698.46, 587.33, 698.46, 783.99, 659.25, 523.25, 659.25,
		698.46, 587.33, 493.88, 587.33, 659.25, 523.25, 392.00, 523.25,
		587.33, 698.46, 659.25, 587.33, 523.25, 0.0, 392.00, 0.0,
	]
	step := mutable_sm.bgm_step % melody.len
	freq := melody[step]

	for i in 0 .. samples_per_step {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-7.0 * (f64(i) / f64(samples_per_step)))
		val := if freq > 0.0 {
			pulse := if math.sin(2.0 * math.pi * freq * (t + mutable_sm.bgm_phase)) > 0.4 { 1.0 } else { -1.0 }
			pulse * env * 12000.0
		} else {
			0.0
		}
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, val)))
	}
	mutable_sm.bgm_phase += step_dur
	mutable_sm.bgm_step++
	sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
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
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
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

fn (sm &SoundManager) play_flap() {
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 180.0 + (t * 1200.0)
		env := 1.0 - (f64(i) / f64(num_samples))
		val := math.sin(2.0 * math.pi * freq * t) * env * 0.35
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_balloon_pop() {
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 2400.0 - (t * 8000.0)
		noise := (rand.f64() * 2.0 - 1.0) * 0.3
		env := math.exp(-15.0 * t)
		val := (math.sin(2.0 * math.pi * math.max(100.0, freq) * t) * 0.6 + noise) * env * 0.5
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_splash() {
	sample_rate := 44100
	duration_ms := 200
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		env := math.exp(-8.0 * t)
		val := noise * env * 0.4
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_fish_gulp() {
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 120.0 + math.sin(t * 50.0) * 80.0
		noise := (rand.f64() * 2.0 - 1.0) * 0.4
		env := math.exp(-6.0 * t)
		val := (math.sin(2.0 * math.pi * freq * t) + noise) * env * 0.55
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_spark_zap() {
	sample_rate := 44100
	duration_ms := 150
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 800.0 + (rand.f64() * 1600.0)
		env := 1.0 - (f64(i) / f64(num_samples))
		val := math.sin(2.0 * math.pi * freq * t) * env * 0.4
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_pickup() {
	sample_rate := 44100
	duration_ms := 100
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 523.25 + (t * 2000.0)
		env := 1.0 - (f64(i) / f64(num_samples))
		val := math.sin(2.0 * math.pi * freq * t) * env * 0.4
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}

fn (sm &SoundManager) play_phase_clear() {
	sample_rate := 44100
	duration_ms := 400
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	notes := [261.63, 329.63, 392.00, 523.25]
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(t * 10.0) % notes.len
		freq := notes[note_idx]
		env := 1.0 - (f64(i) / f64(num_samples))
		val := math.sin(2.0 * math.pi * freq * t) * env * 0.45
		pcm[i] = i16(val * 32767.0)
	}
	sm.play_sound_raw(pcm)
}
