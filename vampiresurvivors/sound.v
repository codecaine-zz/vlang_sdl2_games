module main

import math
import os
import sdl

pub enum BgmTrack {
	gothic_rondo
	vampires_eclipse
	bloodlust_symphony
	off
}

struct ActiveSfx {
mut:
	pcm []i16
	pos int
	vol f32
}

pub struct SoundManager {
pub mut:
	dev           u32
	sound_enabled bool = true
	bgm_track     BgmTrack = .gothic_rondo
	bgm_phase     f64
	bgm_beat      int
	sample_pos    f64
	bgm_pos       int
	bgm_volume    f32 = 0.45
	sfx_volume    f32 = 0.85
	bgm_tracks    map[BgmTrack][]i16
	sfx_clips     map[string][]i16
	active_sfx    []ActiveSfx
}

pub fn new_sound_manager() SoundManager {
	desired := sdl.AudioSpec{
		freq:     44100
		format:   sdl.AudioFormat(sdl.audio_s16sys)
		channels: 1
		samples:  1024
		callback: unsafe { nil }
	}
	mut obtained := sdl.AudioSpec{}

	dev := sdl.open_audio_device(unsafe { nil }, 0, &desired, &obtained, 0)
	if dev > 0 {
		sdl.pause_audio_device(dev, 0)
	}

	mut sm := SoundManager{
		dev:           dev
		sound_enabled: dev > 0
		bgm_track:     .gothic_rondo
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
		os.join_path('vampiresurvivors', 'assets', 'sounds', filename),
		os.join_path('vampiresurvivors', 'assets', 'music', filename),
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
				match name {
					'bgm_rondo' { sm.bgm_tracks[.gothic_rondo] = pcm }
					'bgm_eclipse' { sm.bgm_tracks[.vampires_eclipse] = pcm }
					'bgm_symphony' { sm.bgm_tracks[.bloodlust_symphony] = pcm }
					else { sm.sfx_clips[name] = pcm }
				}
				return
			}
		}
	}
}

fn (mut sm SoundManager) load_all_clips() {
	// Sound effects
	sm.load_clip('whip', 'vs_whip.wav')
	sm.load_clip('wand', 'vs_wand.wav')
	sm.load_clip('knife', 'vs_knife.wav')
	sm.load_clip('axe', 'vs_axe.wav')
	sm.load_clip('bible', 'vs_bible.wav')
	sm.load_clip('lightning', 'vs_lightning.wav')
	sm.load_clip('fire', 'vs_fire.wav')
	sm.load_clip('nuke', 'vs_nuke.wav')
	sm.load_clip('laser', 'vs_laser.wav')
	sm.load_clip('hit', 'vs_hit.wav')
	sm.load_clip('kill', 'vs_kill.wav')
	sm.load_clip('smash', 'vs_smash.wav')
	sm.load_clip('gem', 'vs_gem.wav')
	sm.load_clip('gem_big', 'vs_gem_big.wav')
	sm.load_clip('item', 'vs_item.wav')
	sm.load_clip('heal', 'vs_heal.wav')
	sm.load_clip('freeze', 'vs_freeze.wav')
	sm.load_clip('hurt', 'vs_hurt.wav')
	sm.load_clip('levelup', 'vs_levelup.wav')
	sm.load_clip('chest', 'vs_chest.wav')
	sm.load_clip('evolve', 'vs_evolve.wav')
	sm.load_clip('ultimate', 'vs_ultimate.wav')

	// Music soundtracks
	sm.load_clip('bgm_rondo', 'vampiresurvivors_rondo.wav')
	sm.load_clip('bgm_eclipse', 'vampiresurvivors_eclipse.wav')
	sm.load_clip('bgm_symphony', 'vampiresurvivors_symphony.wav')
}

pub fn (mut sm SoundManager) toggle_sound() {
	sm.sound_enabled = !sm.sound_enabled
	if !sm.sound_enabled && sm.dev > 0 {
		sdl.clear_queued_audio(sm.dev)
		sm.active_sfx.clear()
	}
}

pub fn (mut sm SoundManager) cycle_bgm() {
	sm.bgm_track = match sm.bgm_track {
		.gothic_rondo { BgmTrack.vampires_eclipse }
		.vampires_eclipse { BgmTrack.bloodlust_symphony }
		.bloodlust_symphony { BgmTrack.off }
		.off { BgmTrack.gothic_rondo }
	}
	sm.bgm_pos = 0
	if sm.dev > 0 {
		sdl.clear_queued_audio(sm.dev)
	}
}

fn (mut sm SoundManager) queue_sfx_clip(name string, fallback_fn fn () []i16, vol f32) {
	if !sm.sound_enabled || sm.dev == 0 {
		return
	}
	if name in sm.sfx_clips {
		pcm := sm.sfx_clips[name]
		if pcm.len > 0 {
			if sm.active_sfx.len > 24 {
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
	// Fallback synthesis
	pcm := fallback_fn()
	if pcm.len > 0 {
		if sm.active_sfx.len > 24 {
			sm.active_sfx.delete(0)
		}
		sm.active_sfx << ActiveSfx{
			pcm: pcm
			pos: 0
			vol: vol
		}
	}
}

// Multi-Track Audio Streaming & SFX Mixer Loop
pub fn (mut sm SoundManager) update_bgm(_dt f64, is_active bool) {
	if !sm.sound_enabled || sm.dev == 0 || !is_active {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev)
	if queued > u32(44100 * 2 / 5) {
		return
	}

	sample_rate := 44100.0
	samples_to_gen := 44100 / 10 // 100ms chunk
	mut mixed := []f32{len: samples_to_gen}

	// 1. Render BGM Track
	if sm.bgm_track != .off {
		if sm.bgm_track in sm.bgm_tracks && sm.bgm_tracks[sm.bgm_track].len > 0 {
			track := sm.bgm_tracks[sm.bgm_track]
			track_len := track.len
			for i in 0 .. samples_to_gen {
				sample_idx := (sm.bgm_pos + i) % track_len
				mixed[i] += (f32(track[sample_idx]) / 32768.0) * sm.bgm_volume
			}
			sm.bgm_pos = (sm.bgm_pos + samples_to_gen) % track_len
		} else {
			// Procedural Synthesis Fallback
			match sm.bgm_track {
				.gothic_rondo {
					notes_arpeggio := [
						220.0, 261.63, 329.63, 440.0, 523.25, 440.0, 329.63, 261.63,
						174.61, 220.0, 261.63, 349.23, 440.0, 349.23, 261.63, 220.0,
						196.0, 246.94, 293.66, 392.0, 493.88, 392.0, 293.66, 246.94,
						164.81, 207.65, 246.94, 329.63, 415.30, 329.63, 246.94, 207.65,
					]
					bass_notes := [110.0, 87.31, 98.0, 82.41]
					samples_per_step := int(sample_rate * 0.107)

					for i in 0 .. samples_to_gen {
						total_sample := int(sm.sample_pos) + i
						step_idx := (total_sample / samples_per_step) % notes_arpeggio.len
						measure_idx := (total_sample / (samples_per_step * 8)) % bass_notes.len

						freq_lead := notes_arpeggio[step_idx]
						freq_bass := bass_notes[measure_idx]
						t := f64(total_sample) / sample_rate
						env_lead := 1.0 - (f64(total_sample % samples_per_step) / f64(samples_per_step))

						wave_lead := if math.sin(t * freq_lead * 2.0 * math.pi) > 0.0 { 1.0 } else { -1.0 }
						wave_bass := (t * freq_bass - math.floor(t * freq_bass)) * 2.0 - 1.0

						beat_step := (total_sample / (samples_per_step * 2)) % 4
						beat_sample := total_sample % (samples_per_step * 2)
						mut kick := 0.0
						if beat_step % 2 == 0 {
							kt := f64(beat_sample) / sample_rate
							kick = math.sin(kt * (120.0 - kt * 300.0) * 2.0 * math.pi) * math.exp(-kt * 25.0)
						}

						mix := wave_lead * env_lead * 0.35 + wave_bass * 0.25 + kick * 0.40
						mixed[i] += f32(mix) * sm.bgm_volume
					}
				}
				.vampires_eclipse {
					notes_riff := [
						146.83, 146.83, 293.66, 146.83, 220.0, 146.83, 261.63, 146.83,
						130.81, 130.81, 261.63, 130.81, 196.0, 130.81, 220.0, 130.81,
						116.54, 116.54, 233.08, 116.54, 174.61, 116.54, 196.0, 116.54,
						130.81, 130.81, 261.63, 130.81, 220.0, 246.94, 261.63, 293.66,
					]
					samples_per_step := int(sample_rate * 0.0967)

					for i in 0 .. samples_to_gen {
						total_sample := int(sm.sample_pos) + i
						step_idx := (total_sample / samples_per_step) % notes_riff.len
						freq_riff := notes_riff[step_idx]

						t := f64(total_sample) / sample_rate
						env := 1.0 - (f64(total_sample % samples_per_step) / f64(samples_per_step)) * 0.6
						phase := t * freq_riff
						saw := (phase - math.floor(phase)) * 2.0 - 1.0
						distorted_saw := math.max(-0.8, math.min(0.8, saw * 2.2))

						kick_sample := total_sample % samples_per_step
						kt := f64(kick_sample) / sample_rate
						kick := math.sin(kt * (160.0 - kt * 500.0) * 2.0 * math.pi) * math.exp(-kt * 30.0)

						mix := distorted_saw * env * 0.45 + kick * 0.50
						mixed[i] += f32(mix) * sm.bgm_volume
					}
				}
				.bloodlust_symphony {
					notes_melody := [
						440.0, 493.88, 523.25, 659.25, 587.33, 523.25, 493.88, 440.0,
						392.0, 440.0, 493.88, 587.33, 523.25, 493.88, 440.0, 392.0,
						349.23, 392.0, 440.0, 523.25, 493.88, 440.0, 392.0, 349.23,
						329.63, 415.30, 493.88, 659.25, 783.99, 659.25, 493.88, 415.30,
					]
					samples_per_step := int(sample_rate * 0.0937)

					for i in 0 .. samples_to_gen {
						total_sample := int(sm.sample_pos) + i
						step_idx := (total_sample / samples_per_step) % notes_melody.len
						freq := notes_melody[step_idx]

						t := f64(total_sample) / sample_rate
						env := 1.0 - (f64(total_sample % samples_per_step) / f64(samples_per_step)) * 0.5

						sq := if math.sin(t * freq * 2.0 * math.pi) > 0.0 { 1.0 } else { -1.0 }
						sub := math.sin(t * (freq * 0.5) * 2.0 * math.pi)

						gallop_sample := total_sample % samples_per_step
						gt := f64(gallop_sample) / sample_rate
						gallop_kick := math.sin(gt * 110.0 * 2.0 * math.pi) * math.exp(-gt * 32.0)

						mix := sq * env * 0.35 + sub * 0.25 + gallop_kick * 0.40
						mixed[i] += f32(mix) * sm.bgm_volume
					}
				}
				.off {}
			}
			sm.sample_pos += f64(samples_to_gen)
		}
	}

	// 2. Mix Active Polyphonic SFX Channels
	for sfx_idx := sm.active_sfx.len - 1; sfx_idx >= 0; sfx_idx-- {
		mut sfx := &sm.active_sfx[sfx_idx]
		pcm_len := sfx.pcm.len
		samples_left := pcm_len - sfx.pos
		to_mix := math.min(samples_to_gen, samples_left)
		for i in 0 .. to_mix {
			mixed[i] += (f32(sfx.pcm[sfx.pos + i]) / 32768.0) * sfx.vol * sm.sfx_volume
		}
		sfx.pos += to_mix
		if sfx.pos >= pcm_len {
			sm.active_sfx.delete(sfx_idx)
		}
	}

	// 3. Convert Mixed Buffer to i16 Samples with Soft Clipping
	mut out_samples := []i16{len: samples_to_gen}
	for i in 0 .. samples_to_gen {
		val := math.clamp(mixed[i], -1.0, 1.0)
		out_samples[i] = i16(val * 32767.0)
	}

	sdl.queue_audio(sm.dev, unsafe { out_samples.data }, u32(out_samples.len * 2))
}

// Combat SFX Dispatchers
pub fn (mut sm SoundManager) play_whip_sound() {
	sm.queue_sfx_clip('whip', fn () []i16 {
		num_samples := 3500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 900.0 * math.exp(-t * 22.0) + 90.0
			noise := (math.sin(f64(i) * 0.45) * 2.0 - 1.0) * 0.4
			wave := math.sin(t * freq * 2.0 * math.pi) + noise
			env := math.exp(-t * 28.0)
			samples[i] = i16(wave * env * 14000.0)
		}
		return samples
	}, 0.9)
}

pub fn (mut sm SoundManager) play_magic_wand_sound() {
	sm.queue_sfx_clip('wand', fn () []i16 {
		num_samples := 3000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 450.0 + 800.0 * t
			wave := math.sin(t * freq * 2.0 * math.pi)
			env := (1.0 - f64(i) / f64(num_samples))
			samples[i] = i16(wave * env * 10000.0)
		}
		return samples
	}, 0.8)
}

pub fn (mut sm SoundManager) play_knife_sound() {
	sm.queue_sfx_clip('knife', fn () []i16 {
		num_samples := 2000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 1200.0 - 600.0 * t
			wave := if math.sin(t * freq * 2.0 * math.pi) > 0.0 { 1.0 } else { -1.0 }
			env := (1.0 - f64(i) / f64(num_samples))
			samples[i] = i16(wave * env * 8000.0)
		}
		return samples
	}, 0.8)
}

pub fn (mut sm SoundManager) play_axe_sound() {
	sm.queue_sfx_clip('axe', fn () []i16 {
		num_samples := 4000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 240.0 + math.sin(t * 18.0) * 40.0
			wave := math.sin(t * freq * 2.0 * math.pi)
			env := (1.0 - f64(i) / f64(num_samples))
			samples[i] = i16(wave * env * 11000.0)
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_bible_sound() {
	sm.queue_sfx_clip('bible', fn () []i16 {
		num_samples := 5000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			wave := math.sin(t * 523.25 * 2.0 * math.pi) + 0.5 * math.sin(t * 783.99 * 2.0 * math.pi)
			env := math.exp(-t * 10.0)
			samples[i] = i16(wave * env * 9000.0)
		}
		return samples
	}, 0.8)
}

pub fn (mut sm SoundManager) play_lightning_sound() {
	sm.queue_sfx_clip('lightning', fn () []i16 {
		num_samples := 6000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 31)) * 2.0 - 1.0)
			env := math.exp(-t * 12.0)
			samples[i] = i16(noise * env * 14000.0)
		}
		return samples
	}, 0.9)
}

pub fn (mut sm SoundManager) play_fire_sound() {
	sm.queue_sfx_clip('fire', fn () []i16 {
		num_samples := 5000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 23)) * 2.0 - 1.0)
			env := math.exp(-t * 10.0)
			samples[i] = i16(noise * env * 12000.0)
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_nuke_sound() {
	sm.queue_sfx_clip('nuke', fn () []i16 {
		num_samples := 14000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			sub := math.sin(t * (70.0 - t * 40.0) * 2.0 * math.pi) * math.exp(-t * 3.0)
			noise := (math.sin(f64(i * 47)) * 2.0 - 1.0) * math.exp(-t * 6.0)
			samples[i] = i16((sub * 0.65 + noise * 0.45) * 16000.0)
		}
		return samples
	}, 0.95)
}

pub fn (mut sm SoundManager) play_laser_sound() {
	sm.queue_sfx_clip('laser', fn () []i16 {
		num_samples := 4000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 1600.0 * math.exp(-t * 18.0) + 400.0
			phase := t * freq
			saw := (phase - math.floor(phase)) * 2.0 - 1.0
			env := math.exp(-t * 14.0)
			samples[i] = i16(saw * env * 11000.0)
		}
		return samples
	}, 0.8)
}

pub fn (mut sm SoundManager) play_gem_pickup_sound(val int) {
	clip_name := if val >= 25 { 'gem_big' } else { 'gem' }
	sm.queue_sfx_clip(clip_name, fn () []i16 {
		num_samples := 2500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			wave := math.sin(t * 880.0 * 2.0 * math.pi)
			env := math.exp(-t * 22.0)
			samples[i] = i16(wave * env * 11000.0)
		}
		return samples
	}, 0.8)
}

pub fn (mut sm SoundManager) play_level_up_sound() {
	sm.queue_sfx_clip('levelup', fn () []i16 {
		notes := [523.25, 659.25, 783.99, 1046.50]
		note_len := 2200
		mut samples := []i16{len: notes.len * note_len}
		for n_i, freq in notes {
			for i in 0 .. note_len {
				t := f64(i) / 44100.0
				wave := math.sin(t * freq * 2.0 * math.pi) + 0.3 * math.sin(t * freq * 4.0 * math.pi)
				env := 1.0 - f64(i) / f64(note_len)
				samples[n_i * note_len + i] = i16(wave * env * 12000.0)
			}
		}
		return samples
	}, 0.9)
}

pub fn (mut sm SoundManager) play_hit_sound() {
	sm.queue_sfx_clip('hit', fn () []i16 {
		num_samples := 2000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 37)) * 2.0 - 1.0)
			env := math.exp(-t * 30.0)
			samples[i] = i16(noise * env * 12000.0)
		}
		return samples
	}, 0.75)
}

pub fn (mut sm SoundManager) play_kill_sound() {
	sm.queue_sfx_clip('kill', fn () []i16 {
		num_samples := 2500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 41)) * 2.0 - 1.0)
			env := math.exp(-t * 25.0)
			samples[i] = i16(noise * env * 12000.0)
		}
		return samples
	}, 0.8)
}

pub fn (mut sm SoundManager) play_chest_sound() {
	sm.queue_sfx_clip('chest', fn () []i16 {
		notes := [440.0, 554.37, 659.25, 880.0, 1108.73]
		note_len := 2500
		mut samples := []i16{len: notes.len * note_len}
		for n_i, freq in notes {
			for i in 0 .. note_len {
				t := f64(i) / 44100.0
				sq := if math.sin(t * freq * 2.0 * math.pi) > 0.0 { 1.0 } else { -1.0 }
				env := 1.0 - f64(i) / f64(note_len)
				samples[n_i * note_len + i] = i16(sq * env * 10000.0)
			}
		}
		return samples
	}, 0.9)
}

pub fn (mut sm SoundManager) play_rosary_sound() {
	sm.queue_sfx_clip('lightning', fn () []i16 {
		num_samples := 9000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 43)) * 2.0 - 1.0)
			env := math.exp(-t * 5.0)
			samples[i] = i16(noise * env * 16000.0)
		}
		return samples
	}, 0.9)
}

pub fn (mut sm SoundManager) play_vacuum_sound() {
	sm.queue_sfx_clip('gem_big', fn () []i16 {
		num_samples := 6000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			freq := 200.0 + 800.0 * (t / 0.136)
			wave := math.sin(t * freq * 2.0 * math.pi)
			samples[i] = i16(wave * 11000.0)
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_evolution_sound() {
	sm.queue_sfx_clip('evolve', fn () []i16 {
		notes := [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98]
		note_len := 2200
		mut samples := []i16{len: notes.len * note_len}
		for n_i, freq in notes {
			for i in 0 .. note_len {
				t := f64(i) / 44100.0
				wave := math.sin(t * freq * 2.0 * math.pi) + 0.4 * math.sin(t * freq * 3.0 * math.pi)
				env := 1.0 - f64(i) / f64(note_len)
				samples[n_i * note_len + i] = i16(wave * env * 13000.0)
			}
		}
		return samples
	}, 0.95)
}

pub fn (mut sm SoundManager) play_smash_sound() {
	sm.queue_sfx_clip('smash', fn () []i16 {
		num_samples := 2500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			noise := (math.sin(f64(i * 67)) * 2.0 - 1.0)
			env := math.exp(-t * 35.0)
			samples[i] = i16(noise * env * 11000.0)
		}
		return samples
	}, 0.8)
}

pub fn (mut sm SoundManager) play_heal_sound() {
	sm.queue_sfx_clip('heal', fn () []i16 {
		num_samples := 3500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			wave := math.sin(t * 600.0 * 2.0 * math.pi)
			env := math.exp(-t * 20.0)
			samples[i] = i16(wave * env * 12000.0)
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_freeze_sound() {
	sm.queue_sfx_clip('freeze', fn () []i16 {
		num_samples := 4000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			wave := math.sin(t * 1200.0 * 2.0 * math.pi)
			env := math.exp(-t * 15.0)
			samples[i] = i16(wave * env * 10000.0)
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_hurt_sound() {
	sm.queue_sfx_clip('hurt', fn () []i16 {
		num_samples := 2500
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			wave := math.sin(t * 120.0 * 2.0 * math.pi)
			env := math.exp(-t * 25.0)
			samples[i] = i16(wave * env * 12000.0)
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_ultimate_sound() {
	sm.queue_sfx_clip('ultimate', fn () []i16 {
		num_samples := 12000
		mut samples := []i16{len: num_samples}
		for i in 0 .. num_samples {
			t := f64(i) / 44100.0
			boom := math.sin(t * (240.0 - t * 450.0) * 2.0 * math.pi) * math.exp(-t * 4.0)
			noise := (math.sin(f64(i * 83)) * 2.0 - 1.0) * math.exp(-t * 8.0)
			samples[i] = i16((boom * 0.6 + noise * 0.4) * 16000.0)
		}
		return samples
	}, 0.95)
}

pub fn (mut sm SoundManager) play_combo_sound() {
	sm.queue_sfx_clip('item', fn () []i16 {
		notes := [880.0, 1174.66, 1760.0]
		note_len := 1500
		mut samples := []i16{len: notes.len * note_len}
		for n_i, freq in notes {
			for i in 0 .. note_len {
				t := f64(i) / 44100.0
				wave := math.sin(t * freq * 2.0 * math.pi)
				env := math.exp(-t * 25.0)
				samples[n_i * note_len + i] = i16(wave * env * 11000.0)
			}
		}
		return samples
	}, 0.85)
}

pub fn (mut sm SoundManager) play_jackpot_sound() {
	sm.queue_sfx_clip('chest', fn () []i16 {
		notes := [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98, 2093.00]
		note_len := 1800
		mut samples := []i16{len: notes.len * note_len}
		for n_i, freq in notes {
			for i in 0 .. note_len {
				t := f64(i) / 44100.0
				sq := if math.sin(t * freq * 2.0 * math.pi) > 0.0 { 1.0 } else { -1.0 }
				env := 1.0 - f64(i) / f64(note_len)
				samples[n_i * note_len + i] = i16(sq * env * 12000.0)
			}
		}
		return samples
	}, 0.95)
}
