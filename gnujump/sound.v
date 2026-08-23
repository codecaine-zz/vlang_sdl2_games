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

struct SoundManager {
mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	bgm_pcm       []i16
	bgm_pos       int
	bgm_volume    f32 = 0.35
	sfx_volume    f32 = 0.85
	sfx_clips     map[string][]i16
	active_sfx    []ActiveSfx
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
		os.join_path('gnujump', 'assets', 'music', filename),
		os.join_path('gnujump', 'assets', 'sounds', filename),
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
	sm.load_clip('bgm', 'gnujump_bgm.wav')
	sm.load_clip('jump', 'gnujump_jump.wav')
	sm.load_clip('land', 'gnujump_land.wav')
	sm.load_clip('wall', 'gnujump_wall.wav')
	sm.load_clip('spring', 'gnujump_spring.wav')
	sm.load_clip('crumbly', 'gnujump_crumbly.wav')
	sm.load_clip('lava', 'gnujump_lava.wav')
	sm.load_clip('combo', 'gnujump_combo.wav')
	sm.load_clip('click', 'gnujump_click.wav')
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

fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
		mutable_sm.active_sfx.clear()
	}
	return mutable_sm.sound_enabled
}

fn (sm &SoundManager) update_bgm_stream(is_playing bool) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}

	queued := sdl.get_queued_audio_size(sm.dev)
	if queued >= 4096 {
		return
	}

	mut mutable_sm := unsafe { &SoundManager(sm) }
	chunk_size := 1024
	mut chunk := []i16{len: chunk_size}

	for i in 0 .. chunk_size {
		mut sample_val := f32(0.0)

		// 1. Background Music Loop
		if is_playing && mutable_sm.bgm_pcm.len > 0 {
			sample_val += f32(mutable_sm.bgm_pcm[mutable_sm.bgm_pos]) * mutable_sm.bgm_volume
			mutable_sm.bgm_pos++
			if mutable_sm.bgm_pos >= mutable_sm.bgm_pcm.len {
				mutable_sm.bgm_pos = 0
			}
		}

		// 2. Active Concurrent Sound Effects
		for mut sfx in mutable_sm.active_sfx {
			if sfx.pos < sfx.pcm.len {
				sample_val += f32(sfx.pcm[sfx.pos]) * sfx.volume * mutable_sm.sfx_volume
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
	for idx := mutable_sm.active_sfx.len - 1; idx >= 0; idx-- {
		if mutable_sm.active_sfx[idx].pos >= mutable_sm.active_sfx[idx].pcm.len {
			mutable_sm.active_sfx.delete(idx)
		}
	}

	sdl.queue_audio(sm.dev, chunk.data, u32(chunk.len * 2))
}

fn (sm &SoundManager) play_jump_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['jump'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
		return
	}
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 300.0 + (500.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-20.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 22000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.85)
}

fn (sm &SoundManager) play_land_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['land'] {
		mutable_sm.play_sfx_pcm(clip, 0.8)
		return
	}
	sample_rate := 44100
	duration_ms := 30
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 180.0
		env := math.exp(-40.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.8)
}

fn (sm &SoundManager) play_wall_bounce_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['wall'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
		return
	}
	sample_rate := 44100
	duration_ms := 40
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 420.0 - (200.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-35.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 20000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.85)
}

fn (sm &SoundManager) play_spring_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['spring'] {
		mutable_sm.play_sfx_pcm(clip, 0.95)
		return
	}
	sample_rate := 44100
	duration_ms := 150
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0 + (700.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-12.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 24000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.95)
}

fn (sm &SoundManager) play_crumbly_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['crumbly'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
		return
	}
	sample_rate := 44100
	duration_ms := 90
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0)
		env := math.exp(-25.0 * t)
		val := noise * env * 16000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.85)
}

fn (sm &SoundManager) play_lava_die_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['lava'] {
		mutable_sm.play_sfx_pcm(clip, 0.95)
		return
	}
	sample_rate := 44100
	duration_ms := 300
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 250.0 - (180.0 * (f64(i) / f64(num_samples)))
		noise := (rand.f64() * 2.0 - 1.0) * 0.3
		env := math.exp(-8.0 * t)
		val := (math.sin(2.0 * math.pi * freq * t) + noise) * env * 26000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.95)
}

fn (sm &SoundManager) play_combo_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['combo'] {
		mutable_sm.play_sfx_pcm(clip, 0.9)
		return
	}
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_dur := 60
	total_samples := (sample_rate * note_dur * notes.len) / 1000
	mut pcm := []i16{len: total_samples}
	for n_idx, freq in notes {
		start := (sample_rate * note_dur * n_idx) / 1000
		n_samples := (sample_rate * note_dur) / 1000
		for i in 0 .. n_samples {
			t := f64(i) / f64(sample_rate)
			env := math.exp(-15.0 * t)
			val := math.sin(2.0 * math.pi * freq * t) * env * 22000.0
			pcm[start + i] = i16(val)
		}
	}
	mutable_sm.play_sfx_pcm(pcm, 0.9)
}

fn (sm &SoundManager) play_click_sound() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['click'] {
		mutable_sm.play_sfx_pcm(clip, 0.75)
		return
	}
	sample_rate := 44100
	duration_ms := 30
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 700.0
		env := math.exp(-50.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 14000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.75)
}

fn (sm &SoundManager) cleanup() {
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
	}
}
