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
		'connect4/assets/sounds/${filename}',
		'connect4/assets/music/${filename}',
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
	sm.load_clip('bgm', 'connect4_bgm.wav')
	sm.load_clip('drop', 'connect4_drop.wav')
	sm.load_clip('bounce', 'connect4_bounce.wav')
	sm.load_clip('hover', 'connect4_hover.wav')
	sm.load_clip('win', 'connect4_win.wav')
	sm.load_clip('lose', 'connect4_lose.wav')
	sm.load_clip('draw', 'connect4_draw.wav')
	sm.load_clip('undo', 'connect4_undo.wav')
	sm.load_clip('btn', 'connect4_btn.wav')
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

fn (sm &SoundManager) play_pcm(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev, pcm.data, u32(pcm.len * 2))
}

fn (sm &SoundManager) play_drop_sound() {
	if 'drop' in sm.clips {
		sm.play_clip('drop')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 100
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 280.0 - (190.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-20.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)
		val := harm * env * attack * 24000.0
		pcm[i] = i16(val)
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_land_sound() {
	if 'bounce' in sm.clips {
		sm.play_clip('bounce')
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
		freq := 180.0 - (80.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-32.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.4 * math.sin(math.pi * freq * t)
		val := harm * env * attack * 20000.0
		pcm[i] = i16(val)
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_hover_sound() {
	if 'hover' in sm.clips {
		sm.play_clip('hover')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 25
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 850.0
		env := math.exp(-55.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		val := math.sin(2.0 * math.pi * freq * t) * env * attack * 12000.0
		pcm[i] = i16(val)
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_click_sound() {
	if 'btn' in sm.clips {
		sm.play_clip('btn')
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
		freq := 600.0
		env := math.exp(-45.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		val := math.sin(2.0 * math.pi * freq * t) * env * attack * 16000.0
		pcm[i] = i16(val)
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_win_sound() {
	if 'win' in sm.clips {
		sm.play_clip('win')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51] // C5, E5, G5, C6, E6
	note_dur_ms := 75
	total_samples := (sample_rate * (note_dur_ms * 4 + 180)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_dur := if n_idx == notes.len - 1 { 180 } else { note_dur_ms }
		note_samples := (sample_rate * note_dur) / 1000
		attack_samples := sample_rate * 2 / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples { break }
			t := f64(i) / f64(sample_rate)
			decay := if n_idx == notes.len - 1 { -6.0 } else { -10.0 }
			env := math.exp(decay * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			harm := math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)
			val := harm * env * attack * 22000.0
			pcm[start_sample + i] = i16(val)
		}
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_lose_sound() {
	if 'lose' in sm.clips {
		sm.play_clip('lose')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	notes := [440.0, 415.30, 392.0, 349.23] // A4, Ab4, G4, F4
	note_dur_ms := 110
	total_samples := (sample_rate * (note_dur_ms * 3 + 220)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_dur := if n_idx == notes.len - 1 { 220 } else { note_dur_ms }
		note_samples := (sample_rate * note_dur) / 1000
		attack_samples := sample_rate * 2 / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples { break }
			t := f64(i) / f64(sample_rate)
			decay := if n_idx == notes.len - 1 { -4.0 } else { -7.0 }
			env := math.exp(decay * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			harm := math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(2.0 * math.pi * (freq * 0.5) * t)
			val := harm * env * attack * 20000.0
			pcm[start_sample + i] = i16(val)
		}
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_draw_sound() {
	if 'draw' in sm.clips {
		sm.play_clip('draw')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	notes := [392.0, 440.0, 392.0] // G4, A4, G4
	note_dur_ms := 120
	total_samples := (sample_rate * (note_dur_ms * 2 + 180)) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start_sample := (sample_rate * note_dur_ms * n_idx) / 1000
		note_dur := if n_idx == notes.len - 1 { 180 } else { note_dur_ms }
		note_samples := (sample_rate * note_dur) / 1000
		attack_samples := sample_rate * 2 / 1000
		for i in 0 .. note_samples {
			if start_sample + i >= total_samples { break }
			t := f64(i) / f64(sample_rate)
			decay := -6.0
			env := math.exp(decay * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			harm := math.sin(2.0 * math.pi * freq * t) + 0.2 * math.sin(3.0 * math.pi * freq * t)
			val := harm * env * attack * 18000.0
			pcm[start_sample + i] = i16(val)
		}
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_undo_sound() {
	if 'undo' in sm.clips {
		sm.play_clip('undo')
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 480.0 - (300.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-25.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)
		val := harm * env * attack * 18000.0
		pcm[i] = i16(val)
	}

	sm.play_pcm(pcm)
}

fn (sm &SoundManager) cleanup() {
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
	}
}
