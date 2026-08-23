module main

import math
import os
import sdl

const audio_sample_rate = 44100

struct ActiveSfx {
mut:
	pcm []i16
	pos int
	vol f32
}

pub struct SoundManager {
pub mut:
	dev_id     u32
	enabled    bool = true
	bgm_pos    int
	bgm_tracks map[string][]i16
	sfx_clips  map[string][]i16
	active_sfx []ActiveSfx
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
	mut obtained := sdl.AudioSpec{}
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
		'../assets/sounds/${filename}',
		'../assets/music/${filename}',
		os.join_path('assets', 'sounds', filename),
		os.join_path('assets', 'music', filename),
		os.join_path('..', 'assets', 'sounds', filename),
		os.join_path('..', 'assets', 'music', filename),
		os.join_path('duke', 'assets', 'sounds', filename),
		os.join_path('duke', 'assets', 'music', filename),
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
				num_samples := int(len / 2)
				mut pcm := []i16{len: num_samples}
				unsafe {
					vmemcpy(pcm.data, buf, int(len))
				}
				sdl.free_wav(buf)
				if name.starts_with('bgm_') {
					sm.bgm_tracks[name] = pcm
				} else {
					sm.sfx_clips[name] = pcm
				}
				return
			}
		}
	}
}

fn (mut sm SoundManager) load_all_clips() {
	// SFX
	sm.load_clip('laser', 'duke_laser.wav')
	sm.load_clip('dual_laser', 'duke_dual_laser.wav')
	sm.load_clip('flame', 'duke_flame.wav')
	sm.load_clip('missile', 'duke_missile.wav')
	sm.load_clip('explosion', 'duke_explosion.wav')
	sm.load_clip('jump', 'duke_jump.wav')
	sm.load_clip('pickup', 'duke_pickup.wav')
	sm.load_clip('keycard', 'duke_keycard.wav')
	sm.load_clip('win', 'duke_win.wav')
	sm.load_clip('hurt', 'duke_hurt.wav')
	sm.load_clip('camera', 'duke_camera.wav')
	sm.load_clip('elevator', 'duke_elevator.wav')

	// Music
	sm.load_clip('bgm_theme', 'duke_theme.wav')
	sm.load_clip('bgm_boss', 'duke_boss.wav')
}

pub fn (mut sm SoundManager) toggle_sound() {
	sm.enabled = !sm.enabled
	if !sm.enabled && sm.dev_id > 0 {
		sdl.clear_queued_audio(sm.dev_id)
		sm.active_sfx.clear()
	}
}

fn (mut sm SoundManager) queue_sfx(name string, fallback_fn fn () []i16, vol f32) {
	if !sm.enabled || sm.dev_id == 0 {
		return
	}
	if name in sm.sfx_clips {
		pcm := sm.sfx_clips[name]
		if pcm.len > 0 {
			if sm.active_sfx.len > 16 {
				sm.active_sfx.delete(0)
			}
			sm.active_sfx << ActiveSfx{
				pcm: pcm
				pos: 0
				vol: vol
			}
			return
		}
	}
	// Fallback procedural
	pcm := fallback_fn()
	if pcm.len > 0 {
		if sm.active_sfx.len > 16 {
			sm.active_sfx.delete(0)
		}
		sm.active_sfx << ActiveSfx{
			pcm: pcm
			pos: 0
			vol: vol
		}
	}
}

pub fn (mut sm SoundManager) update_audio(is_boss bool) {
	if !sm.enabled || sm.dev_id == 0 {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued > u32(audio_sample_rate * 2 / 5) {
		return
	}

	samples_to_gen := audio_sample_rate / 10 // 100ms chunk
	mut mixed := []f32{len: samples_to_gen}

	// 1. Stream BGM
	bgm_key := if is_boss { 'bgm_boss' } else { 'bgm_theme' }
	if bgm_key in sm.bgm_tracks && sm.bgm_tracks[bgm_key].len > 0 {
		track := sm.bgm_tracks[bgm_key]
		track_len := track.len
		for i in 0 .. samples_to_gen {
			sample_idx := (sm.bgm_pos + i) % track_len
			mixed[i] += (f32(track[sample_idx]) / 32768.0) * 0.40
		}
		sm.bgm_pos = (sm.bgm_pos + samples_to_gen) % track_len
	}

	// 2. Mix Active SFX Channels
	for sfx_idx := sm.active_sfx.len - 1; sfx_idx >= 0; sfx_idx-- {
		mut sfx := &sm.active_sfx[sfx_idx]
		pcm_len := sfx.pcm.len
		samples_left := pcm_len - sfx.pos
		to_mix := math.min(samples_to_gen, samples_left)
		for i in 0 .. to_mix {
			mixed[i] += (f32(sfx.pcm[sfx.pos + i]) / 32768.0) * sfx.vol * 0.85
		}
		sfx.pos += to_mix
		if sfx.pos >= pcm_len {
			sm.active_sfx.delete(sfx_idx)
		}
	}

	// 3. Convert to i16 PCM
	mut out_samples := []i16{len: samples_to_gen}
	for i in 0 .. samples_to_gen {
		val := math.clamp(mixed[i], -1.0, 1.0)
		out_samples[i] = i16(val * 32767.0)
	}

	sdl.queue_audio(sm.dev_id, unsafe { out_samples.data }, u32(out_samples.len * 2))
}

pub fn (mut sm SoundManager) play_laser_sound() {
	sm.queue_sfx('laser', fn () []i16 {
		count := int(audio_sample_rate * 0.08)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			freq := 880.0 - 550.0 * (t / 0.08)
			env := 1.0 - (t / 0.08)
			val := i16(math.sin(2.0 * math.pi * freq * t) * env * 18000.0)
			samples << val
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_dual_laser_sound() {
	sm.queue_sfx('dual_laser', fn () []i16 {
		count := int(audio_sample_rate * 0.1)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			f1 := 1200.0 - 700.0 * (t / 0.1)
			f2 := 900.0 - 500.0 * (t / 0.1)
			env := 1.0 - (t / 0.1)
			val := i16((math.sin(2.0 * math.pi * f1 * t) * 0.5 + math.sin(2.0 * math.pi * f2 * t) * 0.5) * env * 20000.0)
			samples << val
		}
		return samples
	}, 0.9)
}

pub fn (mut sm SoundManager) play_flame_sound() {
	sm.queue_sfx('flame', fn () []i16 {
		count := int(audio_sample_rate * 0.12)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			noise := (math.sin(f64(i * 3)) * 2.0 - 1.0)
			freq := 180.0 + 80.0 * math.sin(t * 40.0)
			env := 1.0 - (t / 0.12)
			val := i16((noise * 0.6 + math.sin(2.0 * math.pi * freq * t) * 0.4) * env * 16000.0)
			samples << val
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_rocket_sound() {
	sm.queue_sfx('missile', fn () []i16 {
		count := int(audio_sample_rate * 0.15)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			freq := 250.0 + 350.0 * (t / 0.15)
			env := 1.0 - (t / 0.15)
			val := i16(math.sin(2.0 * math.pi * freq * t) * env * 22000.0)
			samples << val
		}
		return samples
	}, 0.9)
}

pub fn (mut sm SoundManager) play_explosion_sound() {
	sm.queue_sfx('explosion', fn () []i16 {
		count := int(audio_sample_rate * 0.3)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			noise := (math.sin(f64(i * 11)) * 2.0 - 1.0)
			env := math.exp(-7.0 * t)
			val := i16(noise * env * 26000.0)
			samples << val
		}
		return samples
	}, 0.95)
}

pub fn (mut sm SoundManager) play_jump_sound() {
	sm.queue_sfx('jump', fn () []i16 {
		count := int(audio_sample_rate * 0.09)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			freq := 240.0 + 260.0 * (t / 0.09)
			env := 1.0 - (t / 0.09)
			val := i16(math.sin(2.0 * math.pi * freq * t) * env * 14000.0)
			samples << val
		}
		return samples
	}, 0.75)
}

pub fn (mut sm SoundManager) play_pickup_sound() {
	sm.queue_sfx('pickup', fn () []i16 {
		notes := [523.25, 659.25, 783.99]
		note_dur := 0.06
		count := int(audio_sample_rate * note_dur * f64(notes.len))
		mut samples := []i16{cap: count}
		for freq in notes {
			sub_count := int(audio_sample_rate * note_dur)
			for i in 0 .. sub_count {
				t := f64(i) / f64(audio_sample_rate)
				env := math.exp(-10.0 * t)
				val := i16(math.sin(2.0 * math.pi * freq * t) * env * 20000.0)
				samples << val
			}
		}
		return samples
	}, 0.75)
}

pub fn (mut sm SoundManager) play_keycard_sound() {
	sm.queue_sfx('keycard', fn () []i16 {
		notes := [880.0, 1174.66, 1760.0]
		note_dur := 0.07
		count := int(audio_sample_rate * note_dur * f64(notes.len))
		mut samples := []i16{cap: count}
		for freq in notes {
			sub_count := int(audio_sample_rate * note_dur)
			for i in 0 .. sub_count {
				t := f64(i) / f64(audio_sample_rate)
				env := math.exp(-8.0 * t)
				val := i16(math.sin(2.0 * math.pi * freq * t) * env * 22000.0)
				samples << val
			}
		}
		return samples
	}, 0.8)
}

pub fn (mut sm SoundManager) play_win_sound() {
	sm.queue_sfx('win', fn () []i16 {
		notes := [440.0, 554.37, 659.25, 880.0, 1108.73]
		note_dur := 0.12
		count := int(audio_sample_rate * note_dur * f64(notes.len))
		mut samples := []i16{cap: count}
		for freq in notes {
			sub_count := int(audio_sample_rate * note_dur)
			for i in 0 .. sub_count {
				t := f64(i) / f64(audio_sample_rate)
				env := 1.0 - (t / note_dur)
				val := i16((math.sin(2.0 * math.pi * freq * t) * 0.7 + math.sin(4.0 * math.pi * freq * t) * 0.3) * env * 22000.0)
				samples << val
			}
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_hurt_sound() {
	sm.queue_sfx('hurt', fn () []i16 {
		count := int(audio_sample_rate * 0.12)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			val := i16(math.sin(2.0 * math.pi * 120.0 * t) * math.exp(-t * 20.0) * 20000.0)
			samples << val
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_camera_sound() {
	sm.queue_sfx('camera', fn () []i16 {
		count := int(audio_sample_rate * 0.10)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			val := i16(math.sin(2.0 * math.pi * 1200.0 * t) * math.exp(-t * 30.0) * 18000.0)
			samples << val
		}
		return samples
	}, 0.8)
}

pub fn (mut sm SoundManager) play_elevator_sound() {
	sm.queue_sfx('elevator', fn () []i16 {
		count := int(audio_sample_rate * 0.12)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			val := i16(math.sin(2.0 * math.pi * 140.0 * t) * 12000.0)
			samples << val
		}
		return samples
	}, 0.6)
}
