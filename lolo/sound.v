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
pub mut:
	dev           sdl.AudioDeviceID
	sound_enabled bool = true
	bgm_enabled   bool = true
	bgm_pcm       []i16
	bgm_pos       int
	bgm_volume    f32 = 0.35
	sfx_volume    f32 = 0.85
	sfx_clips     map[string][]i16
	active_sfx    []ActiveSfx
	bgm_phase     f64
	bgm_tick      u32
	bgm_theme     LevelTheme = .castle
	is_fast_bgm   bool
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
		os.join_path('lolo', 'assets', 'music', filename),
		os.join_path('lolo', 'assets', 'sounds', filename),
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
	sm.load_clip('bgm', 'lolo_bgm.wav')
	sm.load_clip('step', 'lolo_step.wav')
	sm.load_clip('heart', 'lolo_heart.wav')
	sm.load_clip('shot', 'lolo_shot.wav')
	sm.load_clip('egg', 'lolo_egg.wav')
	sm.load_clip('push', 'lolo_push.wav')
	sm.load_clip('chest', 'lolo_chest.wav')
	sm.load_clip('door', 'lolo_door.wav')
	sm.load_clip('victory', 'lolo_victory.wav')
	sm.load_clip('death', 'lolo_death.wav')
	sm.load_clip('medusa', 'lolo_medusa.wav')
	sm.load_clip('warp', 'lolo_warp.wav')
	sm.load_clip('slide', 'lolo_slide.wav')
	sm.load_clip('hammer', 'lolo_hammer.wav')
	sm.load_clip('badge', 'lolo_badge.wav')
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

// --------------------------------------------------
// Synthesized Sound Effects (Fallbacks)
// --------------------------------------------------

fn gen_step() []i16 {
	sample_rate := 44100
	duration_ms := 35
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 320.0 - (180.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-35.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 14000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_heart() []i16 {
	sample_rate := 44100
	notes := [587.33, 880.00, 1174.66]
	note_dur := 55
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-18.0 * t)
			val := (math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)) * env * 18000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_shot() []i16 {
	sample_rate := 44100
	duration_ms := 110
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1400.0 - (1100.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-12.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 24000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_egg() []i16 {
	sample_rate := 44100
	duration_ms := 150
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 300.0 + (700.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-8.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 22000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_push() []i16 {
	sample_rate := 44100
	duration_ms := 80
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 140.0 - (60.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-22.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 25000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_chest() []i16 {
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51]
	note_dur := 80
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-10.0 * t)
			val := (math.sin(2.0 * math.pi * freq * t) + 0.4 * math.sin(4.0 * math.pi * freq * t)) * env * 22000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_undo() []i16 {
	sample_rate := 44100
	duration_ms := 70
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 700.0 - (400.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-25.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 16000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_victory() []i16 {
	sample_rate := 44100
	notes := [659.25, 783.99, 880.00, 1046.50, 1318.51]
	note_dur := 110
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-8.0 * t)
			val := (math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)) * env * 24000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_warp() []i16 {
	sample_rate := 44100
	duration_ms := 250
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 300.0 + 900.0 * (f64(i) / f64(num_samples))
		env := math.sin(math.pi * (f64(i) / f64(num_samples)))
		val := math.sin(2.0 * math.pi * freq * t) * env * 20000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_slide() []i16 {
	sample_rate := 44100
	duration_ms := 180
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * 0.5
		sub := math.sin(2.0 * math.pi * 220.0 * t) * 0.5
		env := math.exp(-12.0 * t)
		val := (noise + sub) * env * 18000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_key() []i16 {
	sample_rate := 44100
	notes := [880.0, 1174.66]
	note_dur := 70
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-20.0 * t)
			val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_spike() []i16 {
	sample_rate := 44100
	duration_ms := 220
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * 0.7
		zap := math.sin(2.0 * math.pi * (800.0 - 500.0 * (f64(i) / f64(num_samples))) * t) * 0.3
		env := math.exp(-10.0 * t)
		val := (noise + zap) * env * 22000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_powerup() []i16 {
	sample_rate := 44100
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_dur := 45
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-15.0 * t)
			val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_prism() []i16 {
	sample_rate := 44100
	duration_ms := 90
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 1200.0 + math.sin(t * 100.0) * 400.0
		env := math.exp(-25.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_phase() []i16 {
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 400.0 + 800.0 * (f64(i) / f64(num_samples))
		env := math.sin(math.pi * (f64(i) / f64(num_samples)))
		val := math.sin(2.0 * math.pi * freq * t) * env * 18000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_plate() []i16 {
	sample_rate := 44100
	duration_ms := 60
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		env := math.exp(-30.0 * t)
		val := math.sin(2.0 * math.pi * 500.0 * t) * env * 16000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_badge() []i16 {
	sample_rate := 44100
	notes := [783.99, 987.77, 1174.66, 1567.98]
	note_dur := 70
	num_samples := (sample_rate * (notes.len * note_dur)) / 1000
	mut pcm := []i16{len: num_samples}
	samples_per_note := (sample_rate * note_dur) / 1000
	for note_idx, freq in notes {
		start_sample := note_idx * samples_per_note
		for i in 0 .. samples_per_note {
			sample_idx := start_sample + i
			if sample_idx >= num_samples {
				break
			}
			t := f64(i) / f64(sample_rate)
			env := math.exp(-12.0 * t)
			val := math.sin(2.0 * math.pi * freq * t) * env * 20000.0
			pcm[sample_idx] = i16(val)
		}
	}
	return pcm
}

fn gen_laser() []i16 {
	sample_rate := 44100
	duration_ms := 140
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 900.0 - (500.0 * (f64(i) / f64(num_samples)))
		env := math.exp(-16.0 * t)
		val := math.sin(2.0 * math.pi * freq * t) * env * 22000.0
		pcm[i] = i16(val)
	}
	return pcm
}

fn gen_hammer() []i16 {
	sample_rate := 44100
	duration_ms := 120
	num_samples := (sample_rate * duration_ms) / 1000
	mut pcm := []i16{len: num_samples}
	for i in 0 .. num_samples {
		t := f64(i) / f64(sample_rate)
		freq := 220.0 - 120.0 * (f64(i) / f64(num_samples))
		env := math.exp(-14.0 * t)
		val := (if math.sin(2.0 * math.pi * freq * t) > 0.0 { 1.0 } else { -1.0 }) * env * 24000.0
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

fn (sm &SoundManager) toggle_sound() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.sound_enabled = !mutable_sm.sound_enabled
	if !mutable_sm.sound_enabled && sm.dev != 0 {
		sdl.clear_queued_audio(sm.dev)
		mutable_sm.active_sfx.clear()
	}
	return mutable_sm.sound_enabled
}

fn (sm &SoundManager) toggle_bgm() bool {
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.bgm_enabled = !mutable_sm.bgm_enabled
	return mutable_sm.bgm_enabled
}

fn (sm &SoundManager) update_bgm_stream(_ LevelTheme, _ bool) {
	if !sm.sound_enabled || !sm.bgm_enabled || sm.dev == 0 {
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
		if mutable_sm.bgm_pcm.len > 0 {
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

fn (sm &SoundManager) play_step() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['step'] {
		mutable_sm.play_sfx_pcm(clip, 0.6)
	} else {
		mutable_sm.play_sfx_pcm(gen_step(), 0.6)
	}
}

fn (sm &SoundManager) play_heart() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['heart'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
	} else {
		mutable_sm.play_sfx_pcm(gen_heart(), 0.85)
	}
}

fn (sm &SoundManager) play_shot() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['shot'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
	} else {
		mutable_sm.play_sfx_pcm(gen_shot(), 0.85)
	}
}

fn (sm &SoundManager) play_egg() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['egg'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
	} else {
		mutable_sm.play_sfx_pcm(gen_egg(), 0.85)
	}
}

fn (sm &SoundManager) play_push() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['push'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
	} else {
		mutable_sm.play_sfx_pcm(gen_push(), 0.85)
	}
}

fn (sm &SoundManager) play_chest() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['chest'] {
		mutable_sm.play_sfx_pcm(clip, 0.95)
	} else {
		mutable_sm.play_sfx_pcm(gen_chest(), 0.95)
	}
}

fn (sm &SoundManager) play_undo() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_undo(), 0.75)
}

fn (sm &SoundManager) play_victory() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['victory'] {
		mutable_sm.play_sfx_pcm(clip, 0.95)
	} else {
		mutable_sm.play_sfx_pcm(gen_victory(), 0.95)
	}
}

fn (sm &SoundManager) play_warp() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['warp'] {
		mutable_sm.play_sfx_pcm(clip, 0.85)
	} else {
		mutable_sm.play_sfx_pcm(gen_warp(), 0.85)
	}
}

fn (sm &SoundManager) play_slide() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['slide'] {
		mutable_sm.play_sfx_pcm(clip, 0.8)
	} else {
		mutable_sm.play_sfx_pcm(gen_slide(), 0.8)
	}
}

fn (sm &SoundManager) play_key() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_key(), 0.85)
}

fn (sm &SoundManager) play_spike() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['medusa'] {
		mutable_sm.play_sfx_pcm(clip, 0.9)
	} else {
		mutable_sm.play_sfx_pcm(gen_spike(), 0.9)
	}
}

fn (sm &SoundManager) play_powerup() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_powerup(), 0.85)
}

fn (sm &SoundManager) play_prism() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_prism(), 0.85)
}

fn (sm &SoundManager) play_phase() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_phase(), 0.85)
}

fn (sm &SoundManager) play_plate() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_plate(), 0.85)
}

fn (sm &SoundManager) play_badge() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['badge'] {
		mutable_sm.play_sfx_pcm(clip, 0.9)
	} else {
		mutable_sm.play_sfx_pcm(gen_badge(), 0.9)
	}
}

fn (sm &SoundManager) play_laser() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	mutable_sm.play_sfx_pcm(gen_laser(), 0.85)
}

fn (sm &SoundManager) play_hammer() {
	if !sm.sound_enabled || sm.dev == 0 { return }
	mut mutable_sm := unsafe { &SoundManager(sm) }
	if clip := sm.sfx_clips['hammer'] {
		mutable_sm.play_sfx_pcm(clip, 0.9)
	} else {
		mutable_sm.play_sfx_pcm(gen_hammer(), 0.9)
	}
}

fn (sm &SoundManager) cleanup() {
	if sm.dev != 0 {
		sdl.close_audio_device(sm.dev)
	}
}
