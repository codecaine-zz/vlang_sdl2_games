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

pub struct SoundManager {
pub mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	bgm_step      int
	bgm_phase     f64
	clips         map[string]SoundClip
}

pub fn new_sound_manager() SoundManager {
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
		'legendofkage/assets/sounds/${filename}',
		'legendofkage/assets/music/${filename}',
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
	sm.load_clip('bgm', 'legendofkage_bgm.wav')
	sm.load_clip('jump', 'kage_jump.wav')
	sm.load_clip('slash', 'kage_slash.wav')
	sm.load_clip('shuriken', 'kage_shuriken.wav')
	sm.load_clip('clash', 'kage_clash.wav')
	sm.load_clip('lightning', 'kage_lightning.wav')
	sm.load_clip('fire', 'kage_fire.wav')
	sm.load_clip('scroll', 'kage_scroll.wav')
	sm.load_clip('stage_clear', 'kage_stage_clear.wav')
}

pub fn (sm &SoundManager) play_clip(name string) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	if clip := sm.clips[name] {
		if clip.buf != unsafe { nil } && clip.len > 0 {
			sdl.queue_audio(sm.dev, clip.buf, clip.len)
		}
	}
}

pub fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
	}
	return mutable_sm.sound_enabled
}

// Feudal Ninja BGM
pub fn (sm &SoundManager) update_bgm(dt f64, is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 || !is_active {
		return
	}
	if 'bgm' in sm.clips {
		queued := sdl.get_queued_audio_size(sm.dev)
		if queued < 8192 {
			sm.play_clip('bgm')
		}
		return
	}

	queued := sdl.get_queued_audio_size(sm.dev)
	if queued > u32(44100 * 2 / 5) {
		return
	}

	mut mutable_sm := unsafe { &SoundManager(sm) }

	sample_rate := 44100
	step_duration := 0.125 // ~120 BPM
	samples_per_step := int(f64(sample_rate) * step_duration)
	mut pcm := []i16{len: samples_per_step}

	// Japanese Hirajoshi / Insen pentatonic scale (A, Bb, D, E, F)
	lead_melody := [
		440.00, 0.0, 466.16, 587.33, 659.25, 587.33, 466.16, 440.00,
		392.00, 0.0, 440.00, 466.16, 587.33, 659.25, 698.46, 0.0,
		880.00, 0.0, 698.46, 659.25, 587.33, 659.25, 698.46, 880.00,
		932.33, 0.0, 880.00, 698.46, 659.25, 587.33, 440.00, 0.0,
	]
	// Taiko drum / bass cadence
	bass_notes := [
		110.00, 110.00, 164.81, 110.00, 130.81, 110.00, 164.81, 110.00,
		98.00,  98.00,  146.83, 98.00,  110.00, 110.00, 164.81, 110.00,
		110.00, 110.00, 164.81, 110.00, 146.83, 146.83, 174.61, 174.61,
		110.00, 110.00, 164.81, 110.00, 98.00,  98.00,  110.00, 110.00,
	]

	step := mutable_sm.bgm_step % lead_melody.len
	lead_freq := lead_melody[step]
	bass_freq := bass_notes[step]

	for i in 0 .. samples_per_step {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-6.0 * (f64(i) / f64(samples_per_step)))

		// Shakuhachi flute-like breathy square wave
		mut lead := 0.0
		if lead_freq > 0.0 {
			sq := if math.sin(2.0 * math.pi * lead_freq * (t + mutable_sm.bgm_phase)) > 0.0 { 1.0 } else { -1.0 }
			breath := (f64(rand.intn(1000) or { 500 }) / 1000.0) - 0.5
			lead = sq * 0.85 + breath * 0.15
		}

		// Low Taiko resonance
		bass := math.sin(2.0 * math.pi * bass_freq * (t + mutable_sm.bgm_phase)) * math.exp(-8.0 * (f64(i) / f64(samples_per_step)))

		// Taiko Rim Click
		mut drum := 0.0
		if step % 4 == 0 && i < samples_per_step / 4 {
			noise := f64((i * 1103515245 + 12345) % 65536) / 32768.0 - 1.0
			drum = noise * math.exp(-35.0 * t)
		}

		sample := (lead * 0.35 + bass * 0.5 + drum * 0.4) * env
		pcm[i] = i16(sample * 16000.0)
	}

	sdl.queue_audio(sm.dev, pcm.data, u32(samples_per_step * 2))
	mutable_sm.bgm_step++
	mutable_sm.bgm_phase += step_duration
}

pub fn (sm &SoundManager) play_jump_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'jump' in sm.clips {
		sm.play_clip('jump')
		return
	}
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 280.0 + 450.0 * (f64(i) / f64(num_samples))
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		pcm[i] = i16(sq * 10000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_sword_slash_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'slash' in sm.clips {
		sm.play_clip('slash')
		return
	}
	sample_rate := 44100
	duration_ms := 100
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		tone := math.sin(2.0 * math.pi * (1200.0 - 800.0 * (f64(i) / f64(num_samples))) * t)
		env := math.exp(-20.0 * t)
		pcm[i] = i16((noise * 0.4 + tone * 0.6) * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_shuriken_throw_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'shuriken' in sm.clips {
		sm.play_clip('shuriken')
		return
	}
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1800.0 + 300.0 * math.sin(t * 80.0)
		sq := if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }
		env := math.exp(-18.0 * t)
		pcm[i] = i16(sq * env * 9000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_blade_clash_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'clash' in sm.clips {
		sm.play_clip('clash')
		return
	}
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		tone1 := math.sin(2.0 * math.pi * 2400.0 * t)
		tone2 := math.sin(2.0 * math.pi * 3600.0 * t)
		env := math.exp(-22.0 * t)
		pcm[i] = i16((tone1 * 0.5 + tone2 * 0.5) * env * 15000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_scroll_pickup_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'scroll' in sm.clips {
		sm.play_clip('scroll')
		return
	}
	sample_rate := 44100
	duration_ms := 250
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(t * 16.0)
		freq := 600.0 + f64(note_idx) * 120.0
		tone := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-8.0 * t)
		pcm[i] = i16(tone * env * 12000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_lightning_jutsu_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'lightning' in sm.clips {
		sm.play_clip('lightning')
		return
	}
	sample_rate := 44100
	duration_ms := 400
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (f64(rand.intn(2000) or { 1000 }) / 1000.0) - 1.0
		bass := math.sin(2.0 * math.pi * 90.0 * t)
		env := math.exp(-6.0 * t)
		pcm[i] = i16((noise * 0.7 + bass * 0.3) * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_stage_clear_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'stage_clear' in sm.clips {
		sm.play_clip('stage_clear')
		return
	}
	sample_rate := 44100
	duration_ms := 600
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		note_idx := int(t * 8.0)
		freq := 440.0 + f64(note_idx % 4) * 110.0
		tone := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-4.0 * t)
		pcm[i] = i16(tone * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_sword_slash() {
	sm.play_sword_slash_sound()
}

pub fn (sm &SoundManager) play_shuriken_throw() {
	sm.play_shuriken_throw_sound()
}

pub fn (sm &SoundManager) play_blade_clash() {
	sm.play_blade_clash_sound()
}

pub fn (sm &SoundManager) play_parry_clink() {
	sm.play_blade_clash_sound()
}

pub fn (sm &SoundManager) play_scroll_jutsu() {
	sm.play_scroll_pickup_sound()
}

pub fn (sm &SoundManager) play_enemy_death() {
	sm.play_sword_slash_sound()
}

pub fn (sm &SoundManager) play_jump_leap() {
	sm.play_jump_sound()
}

pub fn (sm &SoundManager) play_fire_breath() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'fire' in sm.clips {
		sm.play_clip('fire')
		return
	}
	sm.play_shuriken_throw_sound()
}

pub fn (sm &SoundManager) play_die() {
	sm.play_game_over_sound()
}

pub fn (sm &SoundManager) play_stage_clear() {
	sm.play_stage_clear_sound()
}

pub fn (sm &SoundManager) play_game_over_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	sample_rate := 44100
	duration_ms := 500
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 300.0 - 150.0 * (f64(i) / f64(num_samples))
		tone := math.sin(2.0 * math.pi * freq * t)
		env := math.exp(-5.0 * t)
		pcm[i] = i16(tone * env * 13000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}
