module main

import math
import os
import sdl

const audio_sample_rate = 44100

pub struct SoundClip {
pub mut:
	buf &u8 = &u8(unsafe { nil })
	len u32
}

pub struct SoundManager {
pub mut:
	dev_id  u32
	enabled bool = true
	clips   map[string]SoundClip
}

pub fn new_sound_manager() SoundManager {
	mut sm := SoundManager{
		enabled: true
	}
	sm.init()
	sm.load_all_clips()
	return sm
}

pub fn (mut sm SoundManager) init() {
	if sm.dev_id != 0 {
		return
	}
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
}

pub fn (mut sm SoundManager) load_clip(name string, filename string) {
	paths := [
		'assets/sounds/${filename}',
		'assets/music/${filename}',
		'war/assets/sounds/${filename}',
		'war/assets/music/${filename}',
		'../assets/sounds/${filename}',
		'../assets/music/${filename}',
	]
	for p in paths {
		if os.exists(p) {
			mut spec := sdl.AudioSpec{}
			mut buf := &u8(unsafe { nil })
			mut len := u32(0)
			res := sdl.load_wav(p.str, &spec, &buf, &len)
			if !isnil(res) && len > 0 {
				sm.clips[name] = SoundClip{
					buf: buf
					len: len
				}
				return
			}
		}
	}
}

pub fn (mut sm SoundManager) load_all_clips() {
	sm.load_clip('bgm', 'casino_bgm.wav')
	sm.load_clip('flip', 'card_flip.wav')
	sm.load_clip('slide', 'card_deal.wav')
	sm.load_clip('war', 'war_trumpets.wav')
	sm.load_clip('win', 'casino_win.wav')
	sm.load_clip('lose', 'casino_lose.wav')
}

pub fn (sm &SoundManager) play_clip(name string) {
	if !sm.enabled || sm.dev_id == 0 {
		return
	}
	if clip := sm.clips[name] {
		if clip.buf != unsafe { nil } && clip.len > 0 {
			sdl.queue_audio(sm.dev_id, clip.buf, clip.len)
		}
	}
}

pub fn (sm &SoundManager) update_bgm(is_active bool) {
	if !sm.enabled || sm.dev_id == 0 || !is_active {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued < 8192 {
		sm.play_clip('bgm')
	}
}

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.enabled = !sm.enabled
	if !sm.enabled && sm.dev_id != 0 {
		sdl.clear_queued_audio(sm.dev_id)
	}
	return sm.enabled
}

fn (mut sm SoundManager) play_samples(samples []i16) {
	if !sm.enabled || samples.len == 0 {
		return
	}
	if sm.dev_id == 0 {
		sm.init()
		if sm.dev_id == 0 {
			return
		}
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * 2))
}

pub fn (mut sm SoundManager) play_card_flip() {
	if 'flip' in sm.clips {
		sm.play_clip('flip')
		return
	}
	samples := sm.gen_card_flip()
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_card_slide() {
	if 'slide' in sm.clips {
		sm.play_clip('slide')
		return
	}
	samples := sm.gen_card_slide()
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_war() {
	if 'war' in sm.clips {
		sm.play_clip('war')
		return
	}
	samples := sm.gen_war_fanfare()
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_war_clash() {
	sm.play_war()
}

pub fn (mut sm SoundManager) play_win() {
	if 'win' in sm.clips {
		sm.play_clip('win')
		return
	}
	samples := sm.gen_win_sound()
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_round_win() {
	sm.play_win()
}

pub fn (mut sm SoundManager) play_victory() {
	sm.play_win()
}

pub fn (mut sm SoundManager) play_game_over() {
	if 'lose' in sm.clips {
		sm.play_clip('lose')
		return
	}
	samples := sm.gen_lose_sound()
	sm.play_samples(samples)
}

fn (sm &SoundManager) gen_card_flip() []i16 {
	duration := 0.08
	n := int(duration * f64(audio_sample_rate))
	mut samples := []i16{len: n}
	for i in 0 .. n {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 35.0)
		freq := 420.0 + 800.0 * (1.0 - t / duration)
		val := math.sin(2.0 * math.pi * freq * t) * env * 14000.0
		samples[i] = i16(val)
	}
	return samples
}

fn (sm &SoundManager) gen_card_slide() []i16 {
	duration := 0.12
	n := int(duration * f64(audio_sample_rate))
	mut samples := []i16{len: n}
	for i in 0 .. n {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 20.0)
		freq := 280.0 + 350.0 * math.sin(t * 40.0)
		val := math.sin(2.0 * math.pi * freq * t) * env * 10000.0
		samples[i] = i16(val)
	}
	return samples
}

fn (sm &SoundManager) gen_war_fanfare() []i16 {
	duration := 0.6
	n := int(duration * f64(audio_sample_rate))
	mut samples := []i16{len: n}
	notes := [220.0, 277.18, 329.63, 440.0]
	note_dur := duration / f64(notes.len)
	for i in 0 .. n {
		t := f64(i) / f64(audio_sample_rate)
		note_idx := int(t / note_dur) % notes.len
		freq := notes[note_idx]
		t_in_note := t - f64(note_idx) * note_dur
		env := math.exp(-t_in_note * 8.0)
		val := math.sin(2.0 * math.pi * freq * t) * env * 16000.0
		samples[i] = i16(val)
	}
	return samples
}

fn (sm &SoundManager) gen_win_sound() []i16 {
	duration := 0.5
	n := int(duration * f64(audio_sample_rate))
	mut samples := []i16{len: n}
	notes := [523.25, 659.25, 783.99, 1046.50]
	note_dur := duration / f64(notes.len)
	for i in 0 .. n {
		t := f64(i) / f64(audio_sample_rate)
		note_idx := int(t / note_dur) % notes.len
		freq := notes[note_idx]
		t_in_note := t - f64(note_idx) * note_dur
		env := math.exp(-t_in_note * 10.0)
		val := math.sin(2.0 * math.pi * freq * t) * env * 15000.0
		samples[i] = i16(val)
	}
	return samples
}

fn (sm &SoundManager) gen_lose_sound() []i16 {
	duration := 0.4
	n := int(duration * f64(audio_sample_rate))
	mut samples := []i16{len: n}
	for i in 0 .. n {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 8.0)
		freq := 300.0 - 180.0 * (t / duration)
		val := math.sin(2.0 * math.pi * freq * t) * env * 12000.0
		samples[i] = i16(val)
	}
	return samples
}
