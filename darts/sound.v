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
	bgm_volume    f32 = 0.35
	sfx_volume    f32 = 0.88
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
		os.join_path('darts', 'assets', 'music', filename),
		os.join_path('darts', 'assets', 'sounds', filename),
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
	sm.load_clip('bgm', 'darts_bgm.wav')
	sm.load_clip('thud', 'darts_thud.wav')
	sm.load_clip('double', 'darts_double.wav')
	sm.load_clip('triple', 'darts_triple.wav')
	sm.load_clip('bullseye', 'darts_bullseye.wav')
	sm.load_clip('180', 'darts_180.wav')
	sm.load_clip('throw', 'darts_throw.wav')
	sm.load_clip('bust', 'darts_bust.wav')
	sm.load_clip('chalk', 'darts_chalk.wav')
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

pub fn (mut sm SoundManager) play_thud() {
	if clip := sm.sfx_clips['thud'] {
		sm.play_sfx_pcm(clip, 0.85)
		return
	}
	dur := 0.12
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-35.0 * t) * 0.7
		tone := math.sin(2.0 * math.pi * 140.0 * t) * math.exp(-22.0 * t) * 0.8
		pcm[i] = i16((noise + tone) * 16000.0)
	}
	sm.play_sfx_pcm(pcm, 0.85)
}

pub fn (mut sm SoundManager) play_multiplier(mult int) {
	clip_key := if mult >= 3 { 'triple' } else { 'double' }
	if clip := sm.sfx_clips[clip_key] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.25
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	freq := if mult >= 3 { 1174.66 } else { 880.0 }
	for i in 0 .. count {
		t := f64(i) / 44100.0
		decay := math.exp(-10.0 * t)
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * decay * 16000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (mut sm SoundManager) play_bullseye() {
	if clip := sm.sfx_clips['bullseye'] {
		sm.play_sfx_pcm(clip, 0.95)
		return
	}
	dur := 0.40
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		decay := math.exp(-6.0 * t)
		sample := (math.sin(2.0 * math.pi * 1046.5 * t) + math.sin(2.0 * math.pi * 1318.5 * t)) * decay * 0.5
		pcm[i] = i16(sample * 16000.0)
	}
	sm.play_sfx_pcm(pcm, 0.95)
}

pub fn (mut sm SoundManager) play_180_fanfare() {
	if clip := sm.sfx_clips['180'] {
		sm.play_sfx_pcm(clip, 0.95)
		return
	}
	dur := 0.80
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		step := int(t * 8.0) % 4
		freq := match step {
			0 { 523.25 }
			1 { 659.25 }
			2 { 783.99 }
			else { 1046.5 }
		}
		decay := 1.0 - (t / dur) * 0.3
		pcm[i] = i16(math.sin(2.0 * math.pi * freq * t) * decay * 16000.0)
	}
	sm.play_sfx_pcm(pcm, 0.95)
}

pub fn (mut sm SoundManager) play_bust() {
	if clip := sm.sfx_clips['bust'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.35
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		sq := if math.sin(2.0 * math.pi * 110.0 * t) > 0 { 0.4 } else { -0.4 }
		pcm[i] = i16(sq * math.exp(-3.5 * t) * 16000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (mut sm SoundManager) play_throw() {
	if clip := sm.sfx_clips['throw'] {
		sm.play_sfx_pcm(clip, 0.8)
	}
}

pub fn (mut sm SoundManager) play_chalk() {
	if clip := sm.sfx_clips['chalk'] {
		sm.play_sfx_pcm(clip, 0.75)
	}
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
