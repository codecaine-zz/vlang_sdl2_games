module main

import math
import os
import sdl

pub struct SoundClip {
pub mut:
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

pub fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/sounds/${filename}',
		'assets/music/${filename}',
		'yiearkungfu/assets/sounds/${filename}',
		'yiearkungfu/assets/music/${filename}',
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

pub fn (mut sm SoundManager) load_all_clips() {
	sm.load_clip('bgm', 'yiearkungfu_bgm.wav')
	sm.load_clip('punch', 'kungfu_punch.wav')
	sm.load_clip('kick', 'kungfu_kick.wav')
	sm.load_clip('hit', 'kungfu_hit.wav')
	sm.load_clip('jump', 'kungfu_jump.wav')
	sm.load_clip('fire', 'kungfu_fire.wav')
	sm.load_clip('clash', 'kungfu_clash.wav')
	sm.load_clip('ko', 'kungfu_ko.wav')
	sm.load_clip('win', 'kungfu_win.wav')
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

pub fn (sm &SoundManager) update_bgm(dt f64, is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 || !is_active {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev)
	if 'bgm' in sm.clips {
		if queued < 8192 {
			sm.play_clip('bgm')
		}
		return
	}

	if queued > u32(44100 * 2 / 5) {
		return
	}

	mut mutable_sm := unsafe { &SoundManager(sm) }

	sample_rate := 44100
	step_duration := 0.115
	samples_per_step := int(f64(sample_rate) * step_duration)
	mut pcm := []i16{len: samples_per_step}

	lead_melody := [
		349.23, 0.0, 392.00, 415.30, 523.25, 415.30, 392.00, 349.23,
		311.13, 0.0, 349.23, 392.00, 415.30, 523.25, 622.25, 0.0,
		698.46, 0.0, 622.25, 523.25, 415.30, 523.25, 622.25, 698.46,
		783.99, 0.0, 698.46, 622.25, 523.25, 415.30, 349.23, 0.0,
	]
	bass_notes := [
		174.61, 174.61, 261.63, 174.61, 207.65, 174.61, 261.63, 174.61,
		155.56, 155.56, 233.08, 155.56, 174.61, 174.61, 261.63, 174.61,
		174.61, 174.61, 261.63, 174.61, 207.65, 207.65, 261.63, 207.65,
		174.61, 174.61, 261.63, 174.61, 155.56, 155.56, 174.61, 174.61,
	]

	step := mutable_sm.bgm_step % lead_melody.len
	lead_freq := lead_melody[step]
	bass_freq := bass_notes[step]

	for i in 0 .. samples_per_step {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-7.5 * (f64(i) / f64(samples_per_step)))

		mut lead := 0.0
		if lead_freq > 0.0 {
			lead = if math.sin(2.0 * math.pi * lead_freq * (t + mutable_sm.bgm_phase)) > 0.0 { 1.0 } else { -1.0 }
		}

		bass := math.sin(2.0 * math.pi * bass_freq * (t + mutable_sm.bgm_phase))

		mut drum := 0.0
		if step % 2 == 1 && i < samples_per_step / 3 {
			noise := f64((i * 1103515245 + 12345) % 65536) / 32768.0 - 1.0
			drum = noise * math.exp(-28.0 * t)
		}

		sample_val := (lead * 0.26 * env + bass * 0.24 + drum * 0.16) * 11500.0
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, sample_val)))
	}

	mutable_sm.bgm_phase += step_duration
	mutable_sm.bgm_step++
	sdl.queue_audio(mutable_sm.dev, pcm.data, u32(samples_per_step * 2))
}

pub fn (sm &SoundManager) play_punch_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'punch' in sm.clips {
		sm.play_clip('punch')
		return
	}
	sample_rate := 44100
	duration_ms := 65
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 480.0 - 320.0 * (f64(i) / f64(num_samples))
		env := math.exp(-18.0 * t)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 18000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_kick_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'kick' in sm.clips {
		sm.play_clip('kick')
		return
	}
	sample_rate := 44100
	duration_ms := 90
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 320.0 - 240.0 * (f64(i) / f64(num_samples))
		env := math.exp(-14.0 * t)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 22000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_hit_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'hit' in sm.clips {
		sm.play_clip('hit')
		return
	}
	sample_rate := 44100
	duration_ms := 110
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := f64((i * 1664525 + 1013904223) % 65536) / 32768.0 - 1.0
		tone := math.sin(2.0 * math.pi * 140.0 * t)
		env := math.exp(-22.0 * t)
		pcm[i] = i16((noise * 0.7 + tone * 0.3) * env * 26000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
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
		freq := 280.0 + 380.0 * (f64(i) / f64(num_samples))
		env := math.exp(-12.0 * t)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 14000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}

pub fn (sm &SoundManager) play_fire_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'fire' in sm.clips {
		sm.play_clip('fire')
		return
	}
	sm.play_punch_sound()
}

pub fn (sm &SoundManager) play_round_clear_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'win' in sm.clips {
		sm.play_clip('win')
		return
	}
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_duration_ms := 140
	samples_per_note := (sample_rate * note_duration_ms) / 1000
	total_samples := samples_per_note * notes.len
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		st := n_idx * samples_per_note
		for i in 0 .. samples_per_note {
			t := f64(i) / f64(sample_rate)
			env := math.exp(-6.0 * (f64(i) / f64(samples_per_note)))
			pcm[st + i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 16000.0)
		}
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(total_samples * 2))
}

pub fn (sm &SoundManager) play_punch_whoosh() {
	sm.play_punch_sound()
}

pub fn (sm &SoundManager) play_kick_whoosh() {
	sm.play_kick_sound()
}

pub fn (sm &SoundManager) play_hit_impact() {
	sm.play_hit_sound()
}

pub fn (sm &SoundManager) play_weapon_clank() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'clash' in sm.clips {
		sm.play_clip('clash')
		return
	}
	sm.play_punch_sound()
}

pub fn (sm &SoundManager) play_ko_victory() {
	sm.play_round_clear_sound()
}

pub fn (sm &SoundManager) play_ko_defeat() {
	sm.play_game_over_sound()
}

pub fn (sm &SoundManager) play_game_over_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	if 'ko' in sm.clips {
		sm.play_clip('ko')
		return
	}
	sample_rate := 44100
	duration_ms := 400
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 280.0 - 180.0 * (f64(i) / f64(num_samples))
		env := math.exp(-5.0 * t)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 16000.0)
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(num_samples * 2))
}
