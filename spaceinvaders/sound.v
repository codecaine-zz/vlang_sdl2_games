module main

import math
import os
import rand
import sdl

struct SoundClip {
mut:
	samples []i16
}

struct PlayingSound {
pub mut:
	samples []i16
	pos     int
}

struct SoundManager {
pub mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	clips         map[string]SoundClip
	bgm_samples   []i16
	bgm_pos       int
	active_sounds []PlayingSound
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
		'spaceinvaders/assets/sounds/${filename}',
		'spaceinvaders/assets/music/${filename}',
		'../assets/sounds/${filename}',
		'../assets/music/${filename}',
		'/Users/codecaine/vlang_sdl2_games/assets/sounds/${filename}',
		'/Users/codecaine/vlang_sdl2_games/assets/music/${filename}',
	]
	for p in paths {
		if os.exists(p) {
			mut spec := sdl.AudioSpec{}
			mut buf := &u8(unsafe { nil })
			mut len := u32(0)
			res := sdl.load_wav(p.str, &spec, &buf, &len)
			if !isnil(res) && len > 0 {
				sample_count := int(len / 2)
				mut samples := []i16{len: sample_count}
				unsafe {
					v_buf := &i16(buf)
					for i in 0 .. sample_count {
						samples[i] = v_buf[i]
					}
				}
				sdl.free_wav(buf)

				if name == 'bgm' {
					sm.bgm_samples = samples.clone()
				}
				sm.clips[name] = SoundClip{
					samples: samples
				}
				return
			}
		}
	}
}

fn (mut sm SoundManager) load_all_clips() {
	sm.load_clip('laser', 'spaceinvaders_laser.wav')
	sm.load_clip('alien_exp', 'spaceinvaders_alien_exp.wav')
	sm.load_clip('player_exp', 'spaceinvaders_player_exp.wav')
	sm.load_clip('ufo', 'spaceinvaders_ufo.wav')
	sm.load_clip('march1', 'spaceinvaders_march1.wav')
	sm.load_clip('march2', 'spaceinvaders_march2.wav')
	sm.load_clip('march3', 'spaceinvaders_march3.wav')
	sm.load_clip('march4', 'spaceinvaders_march4.wav')
	sm.load_clip('win', 'spaceinvaders_win.wav')
	sm.load_clip('bgm', 'spaceinvaders_bgm.wav')
}

pub fn (mut sm SoundManager) play_clip(name string) bool {
	if !sm.sound_enabled || sm.dev == 0 {
		return false
	}
	if clip := sm.clips[name] {
		if clip.samples.len > 0 {
			sm.active_sounds << PlayingSound{
				samples: clip.samples
				pos:     0
			}
			return true
		}
	}
	return false
}

pub fn (mut sm SoundManager) play_pcm(pcm []i16) {
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sm.active_sounds << PlayingSound{
		samples: pcm
		pos:     0
	}
}

pub fn (mut sm SoundManager) update_bgm(is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}

	queued := sdl.get_queued_audio_size(sm.dev)
	if queued >= 4096 {
		return
	}

	samples_to_fill := 2048
	mut mix_buf := []i16{len: samples_to_fill}

	// Mix BGM into buffer
	if is_active && sm.bgm_samples.len > 0 {
		for i in 0 .. samples_to_fill {
			mix_buf[i] = i16(f32(sm.bgm_samples[sm.bgm_pos]) * 0.38)
			sm.bgm_pos = (sm.bgm_pos + 1) % sm.bgm_samples.len
		}
	}

	// Mix active sound effects
	for s_idx := sm.active_sounds.len - 1; s_idx >= 0; s_idx-- {
		mut ps := &sm.active_sounds[s_idx]
		for i in 0 .. samples_to_fill {
			if ps.pos >= ps.samples.len {
				break
			}
			smp := ps.samples[ps.pos]
			ps.pos++
			mixed := int(mix_buf[i]) + int(smp)
			clamped := if mixed > 32767 {
				32767
			} else if mixed < -32768 {
				-32768
			} else {
				mixed
			}
			mix_buf[i] = i16(clamped)
		}
		if ps.pos >= ps.samples.len {
			sm.active_sounds.delete(s_idx)
		}
	}

	sdl.queue_audio(sm.dev, mix_buf.data, u32(samples_to_fill * 2))
}

fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
		mutable_sm.active_sounds.clear()
	}
	return mutable_sm.sound_enabled
}

fn (sm &SoundManager) play_march_beat(note_idx int) {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	march_name := 'march${(note_idx % 4) + 1}'
	if mutable_sm.play_clip(march_name) {
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

	base_freqs := [175.0, 164.0, 155.0, 146.0]
	freq := base_freqs[note_idx % 4]

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-32.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		sqr := if math.sin(2.0 * math.pi * freq * t) >= 0 { 1.0 } else { -1.0 }
		val := sqr * env * attack * 22000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_laser_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip('laser') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 140
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 980.0 - (720.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-12.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		val := math.sin(2.0 * math.pi * freq * t) * env * attack * 24000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_alien_explosion() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip('alien_exp') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 3 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0) - 1.0
		env := math.exp(-9.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		tone := math.sin(2.0 * math.pi * (140.0 - 90.0 * (f64(i) / f64(num_samples))) * t) * 0.4
		val := (noise * 0.6 + tone) * env * attack * 25000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_player_explosion() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip('player_exp') {
		return
	}
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	sample_rate := 44100
	duration_ms := 650
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0) - 1.0
		low_rumble := math.sin(2.0 * math.pi * 55.0 * t) * 0.6
		env := math.exp(-3.5 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		val := (noise * 0.5 + low_rumble) * env * attack * 26000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_ufo_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip('ufo') {
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
		freq := 480.0 + 160.0 * math.sin(2.0 * math.pi * 14.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		val := math.sin(2.0 * math.pi * freq * t) * attack * 20000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_pcm(pcm)
}

fn (sm &SoundManager) play_player_laser() {
	sm.play_laser_sound()
}

fn (sm &SoundManager) play_ufo_siren() {
	sm.play_ufo_sound()
}

fn (sm &SoundManager) play_ufo_bonus() {
	sm.play_win_sound()
}

fn (sm &SoundManager) play_win_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip('win') {
		return
	}
}

fn (mut sm SoundManager) cleanup() {
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
		sm.dev = 0
	}
	sm.active_sounds.clear()
}
