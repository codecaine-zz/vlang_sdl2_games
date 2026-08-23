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

// Buzzer lock-in ding
pub fn (mut sm SoundManager) play_buzzer_lock() {
	dur := 0.18
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 25.0)
		s := math.sin(t * 880.0 * 2.0 * math.pi) * env * 22000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Correct Answer Chime
pub fn (mut sm SoundManager) play_correct() {
	dur := 0.5
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := if t < 0.16 { 523.25 } else if t < 0.32 { 659.25 } else { 1046.50 }
		env := math.exp(-math.fmod(t, 0.16) * 10.0)
		s := math.sin(t * freq * 2.0 * math.pi) * env * 22000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Wrong Answer Thud / Buzzer
pub fn (mut sm SoundManager) play_wrong() {
	dur := 0.4
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 6.0)
		s := (if (int(t * 130.0) % 2) == 0 { 1.0 } else { -1.0 }) * env * 18000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Victory Fanfare
pub fn (mut sm SoundManager) play_victory() {
	dur := 0.9
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := if t < 0.2 { 523.25 } else if t < 0.4 { 659.25 } else if t < 0.6 { 783.99 } else { 1046.50 }
		env := math.exp(-math.fmod(t, 0.2) * 8.0)
		s := math.sin(t * freq * 2.0 * math.pi) * env * 20000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}
