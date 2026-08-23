module main

import math
import os
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
	waka_phase    bool
	clips         map[string]SoundClip
	bgm_samples   []i16
	bgm_pos       int
	active_sounds []PlayingSound
}

fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/sounds/${filename}',
		'assets/music/${filename}',
		'pacman/assets/sounds/${filename}',
		'pacman/assets/music/${filename}',
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
	sm.load_clip('waka', 'pacman_waka.wav')
	sm.load_clip('power', 'pacman_power.wav')
	sm.load_clip('fruit', 'pacman_fruit.wav')
	sm.load_clip('ghost', 'pacman_ghost.wav')
	sm.load_clip('death', 'pacman_death.wav')
	sm.load_clip('intro', 'pacman_intro.wav')
	sm.load_clip('bgm', 'pacman_bgm.wav')
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

pub fn (mut sm SoundManager) update_mixer(is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}

	queued := sdl.get_queued_audio_size(sm.dev)
	if queued >= 4096 {
		return
	}

	samples_to_fill := 2048
	mut mix_buf := []i16{len: samples_to_fill}

	// 1. Mix BGM into buffer at balanced arcade volume
	if is_active && sm.bgm_samples.len > 0 {
		for i in 0 .. samples_to_fill {
			mix_buf[i] = i16(f32(sm.bgm_samples[sm.bgm_pos]) * 0.40)
			sm.bgm_pos = (sm.bgm_pos + 1) % sm.bgm_samples.len
		}
	}

	// 2. Mix all active sound effect tracks simultaneously
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

fn gen_waka(phase bool) []i16 {
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000
	base_freq := if phase { 460.0 } else { 620.0 }

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := base_freq + (90.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-25.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
		val := harm * env * attack * 26000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_power_pellet() []i16 {
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0 + 300.0 * math.sin(2.0 * math.pi * 20.0 * t)
		env := math.exp(-15.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
		val := harm * env * attack * 26000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_extra_life() []i16 {
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_dur := 0.08
	num_samples := int(f64(sample_rate) * note_dur * f64(notes.len))
	mut pcm := []i16{len: num_samples}

	for n_idx, freq in notes {
		st := int(f64(n_idx) * note_dur * f64(sample_rate))
		samples_per_note := int(note_dur * f64(sample_rate))
		for i in 0 .. samples_per_note {
			idx := st + i
			if idx >= num_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-12.0 * t)
			harm := math.sin(2.0 * math.pi * freq * t) + 0.25 * math.sin(4.0 * math.pi * freq * t)
			pcm[idx] = i16(harm * env * 24000.0)
		}
	}
	return pcm
}

fn gen_frightened_siren() []i16 {
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000
	release_samples := sample_rate * 3 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 760.0 + 240.0 * math.sin(2.0 * math.pi * 16.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		release := if i > num_samples - release_samples { f64(num_samples - i) / f64(release_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)
		val := harm * attack * release * 22000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_eat_ghost() []i16 {
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 600.0 + (1000.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-12.0 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)
		val := harm * env * attack * 26000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_eat_fruit() []i16 {
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	notes := [523.25, 783.99, 1046.50]
	note_dur := num_samples / notes.len
	attack_samples := sample_rate * 2 / 1000

	for note_idx, freq in notes {
		start_idx := note_idx * note_dur
		for i in 0 .. note_dur {
			idx := start_idx + i
			if idx >= num_samples { break }
			t := f64(i) / f64(sample_rate)
			env := math.exp(-14.0 * t)
			attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
			harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
			val := harm * env * attack * 26000.0
			pcm[idx] = i16(val)
		}
	}
	return pcm
}

fn gen_death() []i16 {
	sample_rate := 44100
	duration_ms := 600
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	attack_samples := sample_rate * 2 / 1000

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 950.0 - (800.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-4.5 * t)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		harm := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
		val := harm * env * attack * 26000.0
		pcm[i] = i16(val)
	}
	return pcm
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

pub fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
		mutable_sm.active_sounds.clear()
	}
	return mutable_sm.sound_enabled
}

pub fn (sm &SoundManager) play_intro_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip('intro') {
		return
	}
}

pub fn (sm &SoundManager) play_waka_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip('waka') {
		return
	}
	mutable_sm.waka_phase = !mutable_sm.waka_phase
	pcm := gen_waka(mutable_sm.waka_phase)
	mutable_sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_power_pellet_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip('power') {
		return
	}
	pcm := gen_power_pellet()
	mutable_sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_frightened_siren() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	mut mutable_sm := unsafe { &SoundManager(sm) }
	pcm := gen_frightened_siren()
	mutable_sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_eat_ghost_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip('ghost') {
		return
	}
	pcm := gen_eat_ghost()
	mutable_sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_eat_fruit_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip('fruit') {
		return
	}
	pcm := gen_eat_fruit()
	mutable_sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_death_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if mutable_sm.play_clip('death') {
		return
	}
	pcm := gen_death()
	mutable_sm.play_pcm(pcm)
}

pub fn (sm &SoundManager) play_extra_life_sound() {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	mut mutable_sm := unsafe { &SoundManager(sm) }
	pcm := gen_extra_life()
	mutable_sm.play_pcm(pcm)
}

pub fn (mut sm SoundManager) cleanup() {
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
		sm.dev = 0
	}
	sm.active_sounds.clear()
}
