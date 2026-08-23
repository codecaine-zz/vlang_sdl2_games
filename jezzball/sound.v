module main

import math
import rand
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
	return sm.enabled
}

fn (mut sm SoundManager) play_samples(samples []i16) {
	if !sm.enabled || sm.dev_id == 0 || samples.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

pub fn (mut sm SoundManager) play_ball_bounce(pitch_note int) {
	dur := 0.04
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	freq := 440.0 * math.pow(1.05946, f64(pitch_note % 12))

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 80.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 12000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_wall_build() {
	dur := 0.05
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := (1.0 - t / dur)
		f := 600.0 + (t / dur) * 300.0
		s := math.sin(2.0 * math.pi * f * t)
		val := i16(s * env * 8000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_wall_lock() {
	dur := 0.12
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	freq := 880.0

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 28.0)
		s1 := math.sin(2.0 * math.pi * freq * t)
		s2 := math.sin(2.0 * math.pi * freq * 1.5 * t) * 0.5
		val := i16((s1 + s2) * env * 16000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_wall_shatter() {
	dur := 0.3
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 14.0)
		noise := (rand.f64() * 2.0 - 1.0)
		val := i16(noise * env * 20000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_capture_sweep() {
	dur := 0.28
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.sin(math.pi * (t / dur))
		freq := 300.0 + (t / dur) * 900.0
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 18000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_win_fanfare() {
	dur := 0.5
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	freqs := [523.25, 659.25, 783.99, 1046.50, 1318.51]

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		idx := int(t / 0.1)
		freq := if idx < freqs.len { freqs[idx] } else { freqs.last() }
		local_t := math.fmod(t, 0.1)
		env := math.exp(-local_t * 15.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 17000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_lose_buzzer() {
	dur := 0.4
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 6.0)
		s := math.sin(2.0 * math.pi * 95.0 * t)
		sq := if s > 0.0 { 1.0 } else { -1.0 }
		val := i16(sq * env * 18000.0)
		samples << val
	}
	sm.play_samples(samples)
}
