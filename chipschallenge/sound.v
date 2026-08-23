module main

import math
import os
import rand
import sdl

struct ActiveSfx {
mut:
	pcm    []i16
	pos    int
	volume f32
}

pub struct SoundManager {
pub mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	bgm_pcm       []i16
	bgm_pos       int
	bgm_volume    f32 = 0.38
	sfx_volume    f32 = 0.85
	sfx_clips     map[string][]i16
	active_sfx    []ActiveSfx
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
		'assets/music/${filename}',
		'assets/sounds/${filename}',
		'../assets/music/${filename}',
		'../assets/sounds/${filename}',
		os.join_path('assets', 'music', filename),
		os.join_path('assets', 'sounds', filename),
		os.join_path('..', 'assets', 'music', filename),
		os.join_path('..', 'assets', 'sounds', filename),
		os.join_path('chipschallenge', 'assets', 'music', filename),
		os.join_path('chipschallenge', 'assets', 'sounds', filename),
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
				num_samples := int(len / 2)
				mut pcm := []i16{len: num_samples}
				unsafe {
					vmemcpy(pcm.data, buf, int(len))
				}
				sdl.free_wav(buf)
				if name == 'bgm' {
					sm.bgm_pcm = pcm
				} else {
					sm.sfx_clips[name] = pcm
				}
				return
			}
		}
	}
}

fn (mut sm SoundManager) load_all_clips() {
	sm.load_clip('bgm', 'chipschallenge_bgm.wav')
	sm.load_clip('step', 'chip_step.wav')
	sm.load_clip('chip', 'chip_collect.wav')
	sm.load_clip('key', 'chip_key.wav')
	sm.load_clip('door', 'chip_door.wav')
	sm.load_clip('socket', 'chip_socket.wav')
	sm.load_clip('win', 'chip_win.wav')
	sm.load_clip('death', 'chip_death.wav')
	sm.load_clip('push', 'chip_push.wav')
	sm.load_clip('boot', 'chip_boot.wav')
	sm.load_clip('splash', 'chip_splash.wav')
	sm.load_clip('burn', 'chip_burn.wav')
}

fn (mut sm SoundManager) play_sfx_pcm(pcm []i16, vol f32) {
	if !sm.sound_enabled || sm.dev == 0 || pcm.len == 0 {
		return
	}
	sm.active_sfx << ActiveSfx{
		pcm:    pcm
		pos:    0
		volume: vol
	}
}

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.sound_enabled = !sm.sound_enabled
	if !sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
		sm.active_sfx.clear()
	}
	return sm.sound_enabled
}

// update_bgm mixes real-time background soundtrack stream and active SFX channels
pub fn (mut sm SoundManager) update_bgm(is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}

	queued := sdl.get_queued_audio_size(sm.dev)
	if queued >= 4096 {
		return
	}

	chunk_size := 1024
	mut chunk := []i16{len: chunk_size}

	for i in 0 .. chunk_size {
		mut sample_val := f32(0.0)

		// 1. Background Music Loop
		if is_active && sm.bgm_pcm.len > 0 {
			sample_val += f32(sm.bgm_pcm[sm.bgm_pos]) * sm.bgm_volume
			sm.bgm_pos++
			if sm.bgm_pos >= sm.bgm_pcm.len {
				sm.bgm_pos = 0
			}
		}

		// 2. Active Concurrent Sound Effects
		for mut sfx in sm.active_sfx {
			if sfx.pos < sfx.pcm.len {
				sample_val += f32(sfx.pcm[sfx.pos]) * sfx.volume * sm.sfx_volume
				sfx.pos++
			}
		}

		// 3. Clamping Limiter
		if sample_val > 32767.0 {
			sample_val = 32767.0
		} else if sample_val < -32768.0 {
			sample_val = -32768.0
		}
		chunk[i] = i16(sample_val)
	}

	// 4. Prune completed sound effects
	for idx := sm.active_sfx.len - 1; idx >= 0; idx-- {
		if sm.active_sfx[idx].pos >= sm.active_sfx[idx].pcm.len {
			sm.active_sfx.delete(idx)
		}
	}

	sdl.queue_audio(sm.dev, chunk.data, u32(chunk.len * 2))
}

pub fn (mut sm SoundManager) play_step() {
	if clip := sm.sfx_clips['step'] {
		sm.play_sfx_pcm(clip, 0.6)
		return
	}
	// Procedural fallback
	dur := 0.035
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 110.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * 620.0 * t) * env * 12000.0)
	}
	sm.play_sfx_pcm(pcm, 0.6)
}

pub fn (mut sm SoundManager) play_chip() {
	if clip := sm.sfx_clips['chip'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.12
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := if t < 0.06 { 1318.51 } else { 1975.53 }
		env := math.exp(-math.fmod(t, 0.06) * 32.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 18000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (mut sm SoundManager) play_key() {
	if clip := sm.sfx_clips['key'] {
		sm.play_sfx_pcm(clip, 0.85)
		return
	}
	dur := 0.14
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := if t < 0.07 { 880.0 } else { 1174.66 }
		env := math.exp(-math.fmod(t, 0.07) * 26.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 17000.0)
	}
	sm.play_sfx_pcm(pcm, 0.85)
}

pub fn (mut sm SoundManager) play_door() {
	if clip := sm.sfx_clips['door'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.20
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 14.0)
		freq := 280.0 * math.exp(-t * 8.0) + 90.0
		noise := (rand.f64() * 2.0 - 1.0) * 0.35
		pcm[i] = i16((math.sin(2.0 * math.pi * freq * t) * 0.65 + noise) * env * 18000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (mut sm SoundManager) play_socket() {
	if clip := sm.sfx_clips['socket'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.26
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	notes := [523.25, 659.25, 783.99, 1046.50]
	for i in 0 .. count {
		t := f64(i) / 44100.0
		n_idx := int(t / (dur / 4.0))
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		env := math.exp(-math.fmod(t, dur / 4.0) * 20.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 18000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (mut sm SoundManager) play_win() {
	if clip := sm.sfx_clips['win'] {
		sm.play_sfx_pcm(clip, 0.95)
		return
	}
	dur := 0.50
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	for i in 0 .. count {
		t := f64(i) / 44100.0
		n_idx := int(t / (dur / 5.0))
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		env := math.exp(-math.fmod(t, dur / 5.0) * 10.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 19000.0)
	}
	sm.play_sfx_pcm(pcm, 0.95)
}

pub fn (mut sm SoundManager) play_death() {
	if clip := sm.sfx_clips['death'] {
		sm.play_sfx_pcm(clip, 0.95)
		return
	}
	dur := 0.32
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := 480.0 * math.exp(-t * 9.0) + 60.0
		env := math.exp(-t * 8.0)
		noise := (rand.f64() * 2.0 - 1.0) * 0.25
		pcm[i] = i16((math.sin(2.0 * math.pi * freq * t) * 0.75 + noise) * env * 20000.0)
	}
	sm.play_sfx_pcm(pcm, 0.95)
}

pub fn (mut sm SoundManager) play_push() {
	if clip := sm.sfx_clips['push'] {
		sm.play_sfx_pcm(clip, 0.8)
		return
	}
	dur := 0.15
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.sin(math.pi * (t / dur))
		noise := (rand.f64() * 2.0 - 1.0) * 0.5
		sub := math.sin(2.0 * math.pi * 120.0 * t) * 0.5
		pcm[i] = i16((noise + sub) * env * 16000.0)
	}
	sm.play_sfx_pcm(pcm, 0.8)
}

pub fn (mut sm SoundManager) play_boot() {
	if clip := sm.sfx_clips['boot'] {
		sm.play_sfx_pcm(clip, 0.85)
		return
	}
	dur := 0.16
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := if t < 0.08 { 783.99 } else { 1046.50 }
		env := math.exp(-math.fmod(t, 0.08) * 22.0)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * env * 17000.0)
	}
	sm.play_sfx_pcm(pcm, 0.85)
}

pub fn (mut sm SoundManager) play_splash() {
	if clip := sm.sfx_clips['splash'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.20
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 14.0)
		noise := (rand.f64() * 2.0 - 1.0) * 0.7
		sweep := math.sin(2.0 * math.pi * (340.0 - 220.0 * (t / dur)) * t) * 0.3
		pcm[i] = i16((noise + sweep) * env * 18000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (mut sm SoundManager) play_burn() {
	if clip := sm.sfx_clips['burn'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.22
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 12.0)
		noise := (rand.f64() * 2.0 - 1.0) * 0.8
		pcm[i] = i16(noise * env * 19000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (mut sm SoundManager) cleanup() {
	sm.active_sfx.clear()
	sm.sfx_clips.clear()
	sm.bgm_pcm.clear()
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
		sm.dev = 0
	}
}
