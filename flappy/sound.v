module main

import os
import sdl

const audio_sample_rate = 44100

struct SoundClip {
mut:
	samples []i16
}

struct PlayingSound {
pub mut:
	samples []i16
	pos     int
}

pub struct SoundManager {
pub mut:
	dev_id        u32
	enabled       bool = true
	clips         map[string]SoundClip
	bgm_samples   []i16
	bgm_pos       int
	active_sounds []PlayingSound
}

pub fn new_sound_manager() SoundManager {
	mut sm := SoundManager{}
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
	sm.load_all_clips()
	return sm
}

fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/sounds/${filename}',
		'assets/music/${filename}',
		'flappy/assets/sounds/${filename}',
		'flappy/assets/music/${filename}',
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
	sm.load_clip('flap', 'flappy_flap.wav')
	sm.load_clip('point', 'flappy_point.wav')
	sm.load_clip('hit', 'flappy_hit.wav')
	sm.load_clip('die', 'flappy_die.wav')
	sm.load_clip('swoosh', 'flappy_swoosh.wav')
	sm.load_clip('bgm', 'flappy_bgm.wav')
}

pub fn (mut sm SoundManager) toggle_sound() {
	sm.enabled = !sm.enabled
	if !sm.enabled && sm.dev_id != 0 {
		sdl.clear_queued_audio(sm.dev_id)
		sm.active_sounds.clear()
	}
}

pub fn (mut sm SoundManager) play_clip(name string) bool {
	if !sm.enabled || sm.dev_id == 0 {
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

pub fn (mut sm SoundManager) play_samples(samples []i16) {
	if !sm.enabled || sm.dev_id == 0 || samples.len == 0 {
		return
	}
	sm.active_sounds << PlayingSound{
		samples: samples
		pos:     0
	}
}

pub fn (mut sm SoundManager) update_bgm(is_active bool) {
	if !sm.enabled || sm.dev_id == 0 {
		return
	}

	queued := sdl.get_queued_audio_size(sm.dev_id)
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

	sdl.queue_audio(sm.dev_id, mix_buf.data, u32(samples_to_fill * 2))
}

pub fn (mut sm SoundManager) play_flap_sound() {
	if sm.play_clip('flap') {
		return
	}
}

pub fn (mut sm SoundManager) play_score_sound() {
	if sm.play_clip('point') {
		return
	}
}

pub fn (mut sm SoundManager) play_hit_sound() {
	if sm.play_clip('hit') {
		return
	}
}

pub fn (mut sm SoundManager) play_die_sound() {
	if sm.play_clip('die') {
		return
	}
}

pub fn (mut sm SoundManager) play_swoosh_sound() {
	if sm.play_clip('swoosh') {
		return
	}
}

pub fn (mut sm SoundManager) cleanup() {
	if sm.dev_id != 0 {
		sdl.close_audio_device(sm.dev_id)
		sm.dev_id = 0
	}
	sm.active_sounds.clear()
}
