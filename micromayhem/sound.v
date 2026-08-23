module main

import math
import sdl

const audio_sample_rate = 44100

pub struct SoundManager {
pub mut:
	dev_id  u32
	enabled bool = true
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
	obtained := sdl.AudioSpec{}
	dev := sdl.open_audio_device(unsafe { nil }, 0, &spec, &obtained, 0)
	if dev > 0 {
		sm.dev_id = dev
		sdl.pause_audio_device(dev, 0)
	}
	return sm
}

pub fn (mut sm SoundManager) toggle_sound() bool {
	sm.enabled = !sm.enabled
	if !sm.enabled && sm.dev_id != 0 {
		sdl.clear_queued_audio(sm.dev_id)
	}
	return sm.enabled
}

fn (mut sm SoundManager) play_samples(samples []i16) {
	if !sm.enabled || sm.dev_id == 0 || samples.len == 0 {
		return
	}
	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued > u32(audio_sample_rate * int(sizeof(i16)) / 4) {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

// Clock tick
pub fn (mut sm SoundManager) play_tick(pitch f64) {
	dur := 0.04
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 80.0)
		s := math.sin(t * pitch * 2.0 * math.pi) * env * 16000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Micro-game Success Fanfare
pub fn (mut sm SoundManager) play_win() {
	dur := 0.4
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := if t < 0.13 { 523.25 } else if t < 0.26 { 659.25 } else { 1046.50 }
		env := math.exp(-math.fmod(t, 0.13) * 12.0)
		s := math.sin(t * freq * 2.0 * math.pi) * env * 20000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Micro-game Failure Buzzer
pub fn (mut sm SoundManager) play_fail() {
	dur := 0.45
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 180.0 - t * 60.0
		env := math.exp(-t * 4.0)
		s := (if (int(t * freq) % 2) == 0 { 1.0 } else { -1.0 }) * env * 18000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Speed Up Fanfare
pub fn (mut sm SoundManager) play_speedup() {
	dur := 0.6
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 400.0 + t * 600.0
		env := math.exp(-t * 3.0)
		s := math.sin(t * freq * 2.0 * math.pi) * env * 22000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Interstitial Action Ding
pub fn (mut sm SoundManager) play_pop() {
	dur := 0.08
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 40.0)
		s := math.sin(t * 880.0 * 2.0 * math.pi) * env * 18000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}
