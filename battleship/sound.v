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
		os.join_path('battleship', 'assets', 'music', filename),
		os.join_path('battleship', 'assets', 'sounds', filename),
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
	sm.load_clip('bgm', 'battleship_bgm.wav')
	sm.load_clip('sonar', 'battleship_sonar.wav')
	sm.load_clip('launch', 'battleship_launch.wav')
	sm.load_clip('splash', 'battleship_splash.wav')
	sm.load_clip('hit', 'battleship_hit.wav')
	sm.load_clip('sunk', 'battleship_sunk.wav')
	sm.load_clip('victory', 'battleship_victory.wav')
	sm.load_clip('place', 'battleship_place.wav')
	sm.load_clip('radar', 'battleship_radar.wav')
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

pub fn (mut sm SoundManager) play_sonar() {
	if clip := sm.sfx_clips['sonar'] {
		sm.play_sfx_pcm(clip, 0.85)
		return
	}
	dur := 0.45
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 6.0)
		pcm[i] = i16(math.sin(t * 1150.0 * 2.0 * math.pi) * env * 22000.0)
	}
	sm.play_sfx_pcm(pcm, 0.85)
}

pub fn (mut sm SoundManager) play_launch() {
	if clip := sm.sfx_clips['launch'] {
		sm.play_sfx_pcm(clip, 0.8)
		return
	}
	dur := 0.25
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := 800.0 - t * 400.0
		env := math.exp(-t * 5.0)
		pcm[i] = i16(math.sin(t * freq * 2.0 * math.pi) * env * 18000.0)
	}
	sm.play_sfx_pcm(pcm, 0.8)
}

pub fn (mut sm SoundManager) play_splash() {
	if clip := sm.sfx_clips['splash'] {
		sm.play_sfx_pcm(clip, 0.85)
		return
	}
	dur := 0.35
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 8.0)
		noise := (rand.f64() * 2.0 - 1.0)
		pcm[i] = i16((noise * 0.7 + math.sin(t * 180.0 * 2.0 * math.pi) * 0.3) * env * 20000.0)
	}
	sm.play_sfx_pcm(pcm, 0.85)
}

pub fn (mut sm SoundManager) play_hit() {
	if clip := sm.sfx_clips['hit'] {
		sm.play_sfx_pcm(clip, 0.95)
		return
	}
	dur := 0.40
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		env := math.exp(-t * 7.0)
		noise := (rand.f64() * 2.0 - 1.0)
		sub := math.sin(t * 75.0 * 2.0 * math.pi)
		pcm[i] = i16((noise * 0.6 + sub * 0.4) * env * 26000.0)
	}
	sm.play_sfx_pcm(pcm, 0.95)
}

pub fn (mut sm SoundManager) play_sunk() {
	if clip := sm.sfx_clips['sunk'] {
		sm.play_sfx_pcm(clip, 1.0)
		return
	}
	dur := 0.70
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := 300.0 + math.sin(t * 18.0) * 120.0
		env := math.exp(-t * 2.5)
		pcm[i] = i16(math.sin(t * freq * 2.0 * math.pi) * env * 24000.0)
	}
	sm.play_sfx_pcm(pcm, 1.0)
}

pub fn (mut sm SoundManager) play_victory() {
	if clip := sm.sfx_clips['victory'] {
		sm.play_sfx_pcm(clip, 0.9)
		return
	}
	dur := 0.80
	count := int(44100 * dur)
	mut pcm := []i16{len: count}
	for i in 0 .. count {
		t := f64(i) / 44100.0
		freq := if t < 0.2 { 523.25 } else if t < 0.4 { 659.25 } else if t < 0.6 { 783.99 } else { 1046.50 }
		env := math.exp(-math.fmod(t, 0.2) * 8.0)
		pcm[i] = i16(math.sin(t * freq * 2.0 * math.pi) * env * 22000.0)
	}
	sm.play_sfx_pcm(pcm, 0.9)
}

pub fn (mut sm SoundManager) play_place() {
	if clip := sm.sfx_clips['place'] {
		sm.play_sfx_pcm(clip, 0.75)
		return
	}
	sm.play_sonar()
}

pub fn (mut sm SoundManager) play_radar() {
	if clip := sm.sfx_clips['radar'] {
		sm.play_sfx_pcm(clip, 0.85)
		return
	}
	sm.play_sonar()
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
