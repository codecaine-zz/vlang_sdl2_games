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
	bgm_volume    f32 = 0.42
	sfx_volume    f32 = 0.88
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
		os.join_path('sinksub', 'assets', 'music', filename),
		os.join_path('sinksub', 'assets', 'sounds', filename),
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
	sm.load_clip('bgm', 'sinksub_bgm.wav')
	sm.load_clip('explosion', 'explosion.wav')
	sm.load_clip('impact', 'hit.wav')
	sm.load_clip('powerup', 'powerup.wav')
	sm.load_clip('click', 'click.wav')
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

// update_bgm mixes BGM soundtrack and concurrent active SFX in real-time
fn (sm &SoundManager) update_bgm(is_active bool) {
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
		if is_active && mutable_sm.bgm_pcm.len > 0 {
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

fn (sm &SoundManager) play_sonar_ping() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	duration_ms := 600
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		// Main Ping 1046.50Hz with decay
		ping := math.sin(2.0 * math.pi * 1046.50 * t) * math.exp(-6.0 * t)
		// Underwater echo reflection
		echo_t := math.max(0.0, t - 0.16)
		echo := if t > 0.16 {
			math.sin(2.0 * math.pi * 783.99 * echo_t) * math.exp(-7.5 * echo_t) * 0.45
		} else {
			0.0
		}
		val := (ping + echo) * 22000.0
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, val)))
	}
	mutable_sm.play_sfx_pcm(pcm, 0.75)
}

fn (sm &SoundManager) play_splash() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-12.0 * t)
		sweep := math.sin(2.0 * math.pi * (320.0 - 200.0 * (f64(i) / f64(num_samples))) * t) * math.exp(-14.0 * t)
		val := (noise * 0.65 + sweep * 0.35) * 20000.0
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, val)))
	}
	mutable_sm.play_sfx_pcm(pcm, 0.65)
}

fn (sm &SoundManager) play_launch() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	duration_ms := 130
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 140.0 + (480.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-18.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 22000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.7)
}

fn (sm &SoundManager) play_explosion(is_deep bool) {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	duration_ms := if is_deep { 520 } else { 320 }
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := math.max(16.0, (if is_deep { 95.0 } else { 190.0 }) - (75.0 * (f64(i) / f64(num_samples))))
		rumble := math.sin(2.0 * math.pi * freq * t)
		noise := (rand.f64() * 2.0 - 1.0)
		env := math.exp((if is_deep { -5.5 } else { -11.0 }) * t)
		val := (rumble * 0.7 + noise * 0.3) * env * 28000.0
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, val)))
	}
	mutable_sm.play_sfx_pcm(pcm, 0.95)
}

fn (sm &SoundManager) play_powerup() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	notes := [440.0, 554.37, 659.25, 880.0, 1108.73]
	note_dur := 50
	total_samples := (sample_rate * note_dur * notes.len) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start := (sample_rate * note_dur * n_idx) / 1000
		n_samples := (sample_rate * note_dur) / 1000
		for i in 0 .. n_samples {
			t := f64(i) / f64(sample_rate)
			env := math.exp(-12.0 * t)
			val := math.sin(2.0 * math.pi * freq * t) * env * 20000.0
			pcm[start + i] = i16(val)
		}
	}
	mutable_sm.play_sfx_pcm(pcm, 0.85)
}

fn (sm &SoundManager) play_nuke() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	duration_ms := 850
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := math.max(18.0, 1200.0 - (1150.0 * math.pow(f64(i) / f64(num_samples), 0.5)))
		noise := (rand.f64() * 2.0 - 1.0) * 0.45
		env := math.exp(-3.2 * t)
		val := (math.sin(2.0 * math.pi * freq * t) + noise) * env * 30000.0
		pcm[i] = i16(math.max(-32767.0, math.min(32767.0, val)))
	}
	mutable_sm.play_sfx_pcm(pcm, 1.0)
}

fn (sm &SoundManager) play_rank_up() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	notes := [261.63, 329.63, 392.00, 523.25, 659.25, 783.99]
	note_dur := 70
	total_samples := (sample_rate * note_dur * notes.len) / 1000
	mut pcm := []i16{len: total_samples}

	for n_idx, freq in notes {
		start := (sample_rate * note_dur * n_idx) / 1000
		n_samples := (sample_rate * note_dur) / 1000
		for i in 0 .. n_samples {
			t := f64(i) / f64(sample_rate)
			env := math.exp(-9.0 * t)
			val := math.sin(2.0 * math.pi * freq * t) * env * 24000.0
			pcm[start + i] = i16(val)
		}
	}
	mutable_sm.play_sfx_pcm(pcm, 0.9)
}

fn (sm &SoundManager) play_torpedo_warning() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		val := math.sin(2.0 * math.pi * 880.0 * t) * math.exp(-18.0 * t) * 16000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.6)
}

fn (sm &SoundManager) play_click_sound() {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	sample_rate := 44100
	duration_ms := 25
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}

	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-50.0 * t)
		val := math.sin(2.0 * math.pi * 720.0 * t) * env * 14000.0
		pcm[i] = i16(val)
	}
	mutable_sm.play_sfx_pcm(pcm, 0.5)
}

fn (mut sm SoundManager) cleanup() {
	sm.active_sfx.clear()
	sm.sfx_clips.clear()
	sm.bgm_pcm.clear()
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
		sm.dev = 0
	}
}
