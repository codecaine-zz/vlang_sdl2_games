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
		os.join_path('scorchedearth', 'assets', 'sounds', filename),
		os.join_path('scorchedearth', 'assets', 'music', filename),
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
	sm.load_clip('shot', 'scorched_shot.wav')
	sm.load_clip('nuke_launch', 'scorched_nuke_launch.wav')
	sm.load_clip('mirv_split', 'scorched_mirv_split.wav')
	sm.load_clip('drill', 'scorched_drill.wav')
	sm.load_clip('napalm', 'scorched_napalm.wav')
	sm.load_clip('dirt', 'scorched_dirt.wav')
	sm.load_clip('explosion', 'scorched_explosion.wav')
	sm.load_clip('nuke_detonate', 'scorched_nuke_detonate.wav')
	sm.load_clip('cash', 'scorched_cash.wav')
	sm.load_clip('select', 'scorched_select.wav')
	sm.load_clip('win', 'scorched_win.wav')

	// Music
	sm.load_clip('bgm_theme', 'scorched_theme.wav')
	sm.load_clip('bgm_shop', 'scorched_shop.wav')
}

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.enabled = !sm.enabled
	if !sm.enabled && sm.dev_id > 0 {
		sdl.clear_queued_audio(sm.dev_id)
		sm.active_sfx.clear()
	}
	return sm.enabled
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

pub fn (mut sm SoundManager) update_audio(in_shop bool) {
	if !sm.enabled || sm.dev_id == 0 {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued > u32(audio_sample_rate * 2 / 5) {
		return
	}

	samples_to_gen := audio_sample_rate / 10
	mut mixed := []f32{len: samples_to_gen}

	// 1. Stream BGM
	bgm_key := if in_shop { 'bgm_shop' } else { 'bgm_theme' }
	if bgm_key in sm.bgm_tracks && sm.bgm_tracks[bgm_key].len > 0 {
		track := sm.bgm_tracks[bgm_key]
		track_len := track.len
		for i in 0 .. samples_to_gen {
			sample_idx := (sm.bgm_pos + i) % track_len
			mixed[i] += (f32(track[sample_idx]) / 32768.0) * 0.38
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
			mixed[i] += (f32(sfx.pcm[sfx.pos + i]) / 32768.0) * sfx.vol * 0.9
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

pub fn (mut sm SoundManager) play_shot(wtype WeaponType) {
	match wtype {
		.baby_nuke {
			sm.queue_sfx('nuke_launch', fn () []i16 {
				dur := 0.28
				count := int(audio_sample_rate * dur)
				mut samples := []i16{cap: count}
				for i in 0 .. count {
					t := f64(i) / f64(audio_sample_rate)
					freq := 120.0 + 320.0 * (t / dur)
					sub := math.sin(2.0 * math.pi * freq * t)
					val := i16(sub * math.exp(-t * 6.0) * 24000.0)
					samples << val
				}
				return samples
			}, 0.95)
		}
		.digger {
			sm.queue_sfx('drill', fn () []i16 {
				dur := 0.22
				count := int(audio_sample_rate * dur)
				mut samples := []i16{cap: count}
				for i in 0 .. count {
					t := f64(i) / f64(audio_sample_rate)
					freq := 600.0 + math.sin(t * 120.0) * 180.0
					val := i16(math.sin(2.0 * math.pi * freq * t) * 20000.0)
					samples << val
				}
				return samples
			}, 0.85)
		}
		.napalm {
			sm.queue_sfx('napalm', fn () []i16 {
				dur := 0.25
				count := int(audio_sample_rate * dur)
				mut samples := []i16{cap: count}
				for i in 0 .. count {
					t := f64(i) / f64(audio_sample_rate)
					val := i16(math.sin(2.0 * math.pi * 180.0 * t) * math.exp(-t * 8.0) * 20000.0)
					samples << val
				}
				return samples
			}, 0.85)
		}
		else {
			sm.queue_sfx('shot', fn () []i16 {
				dur := 0.22
				count := int(audio_sample_rate * dur)
				mut samples := []i16{cap: count}
				for i in 0 .. count {
					t := f64(i) / f64(audio_sample_rate)
					env := math.exp(-t * 22.0)
					freq := 240.0 * math.exp(-t * 16.0) + 45.0
					val := i16(math.sin(2.0 * math.pi * freq * t) * env * 22000.0)
					samples << val
				}
				return samples
			}, 0.9)
		}
	}
}

pub fn (mut sm SoundManager) play_explosion(is_nuke bool) {
	key := if is_nuke { 'nuke_detonate' } else { 'explosion' }
	sm.queue_sfx(key, fn [is_nuke] () []i16 {
		dur := if is_nuke { 0.65 } else { 0.35 }
		count := int(audio_sample_rate * dur)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			env := math.exp(-t * (if is_nuke { 4.5 } else { 12.0 }))
			val := i16(math.sin(2.0 * math.pi * (if is_nuke { 55.0 } else { 90.0 }) * t) * env * 24000.0)
			samples << val
		}
		return samples
	}, 0.95)
}

pub fn (mut sm SoundManager) play_mirv_split() {
	sm.queue_sfx('mirv_split', fn () []i16 {
		dur := 0.12
		count := int(audio_sample_rate * dur)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			env := math.exp(-t * 35.0)
			freq := 880.0 * math.exp(-t * 20.0)
			val := i16(math.sin(2.0 * math.pi * freq * t) * env * 16000.0)
			samples << val
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_dirt() {
	sm.queue_sfx('dirt', fn () []i16 {
		dur := 0.2
		count := int(audio_sample_rate * dur)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			val := i16(math.sin(2.0 * math.pi * 100.0 * t) * math.exp(-t * 12.0) * 20000.0)
			samples << val
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_drill() {
	sm.queue_sfx('drill', fn () []i16 {
		dur := 0.2
		count := int(audio_sample_rate * dur)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			val := i16(math.sin(2.0 * math.pi * 600.0 * t) * 16000.0)
			samples << val
		}
		return samples
	}, 0.8)
}

pub fn (mut sm SoundManager) play_cash() {
	sm.queue_sfx('cash', fn () []i16 {
		dur := 0.2
		count := int(audio_sample_rate * dur)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			freq := if t < 0.08 { 1318.51 } else { 1760.00 }
			env := math.exp(-math.fmod(t, 0.08) * 25.0)
			val := i16(math.sin(2.0 * math.pi * freq * t) * env * 14000.0)
			samples << val
		}
		return samples
	}, 0.8)
}

pub fn (mut sm SoundManager) play_select() {
	sm.queue_sfx('select', fn () []i16 {
		dur := 0.06
		count := int(audio_sample_rate * dur)
		mut samples := []i16{cap: count}
		for i in 0 .. count {
			t := f64(i) / f64(audio_sample_rate)
			val := i16(math.sin(2.0 * math.pi * 750.0 * t) * (1.0 - t / dur) * 16000.0)
			samples << val
		}
		return samples
	}, 0.75)
}

pub fn (mut sm SoundManager) play_win() {
	sm.queue_sfx('win', fn () []i16 {
		notes := [523.25, 659.25, 783.99, 1046.50]
		note_dur := 0.12
		count := int(audio_sample_rate * note_dur * f64(notes.len))
		mut samples := []i16{cap: count}
		for freq in notes {
			sub_count := int(audio_sample_rate * note_dur)
			for i in 0 .. sub_count {
				t := f64(i) / f64(audio_sample_rate)
				val := i16(math.sin(2.0 * math.pi * freq * t) * 20000.0)
				samples << val
			}
		}
		return samples
	}, 0.85)
}
