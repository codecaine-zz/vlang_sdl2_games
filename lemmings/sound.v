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
	if queued > u32(audio_sample_rate * int(sizeof(i16)) / 3) {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

// "Let's Go!" / Level Start Chime
pub fn (mut sm SoundManager) play_start() {
	dur := 0.28
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	notes := [587.33, 739.99, 880.00, 1174.66]

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		n_idx := int(t / (dur / 4.0))
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		local_t := math.fmod(t, dur / 4.0)
		env := math.exp(-local_t * 18.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 14000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Builder Step Placement
pub fn (mut sm SoundManager) play_brick() {
	dur := 0.05
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 60.0)
		s := math.sin(2.0 * math.pi * 520.0 * t)
		val := i16(s * env * 12000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// "Oh No!" / Bomber Pop
pub fn (mut sm SoundManager) play_oh_no() {
	dur := 0.16
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 950.0 * math.exp(-t * 12.0)
		env := math.exp(-t * 15.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 15000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Explosion Burst
pub fn (mut sm SoundManager) play_explode() {
	dur := 0.25
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 14.0)
		noise := (rand.f64() * 2.0 - 1.0)
		sub := math.sin(2.0 * math.pi * 75.0 * t)
		val := i16(math.clamp((noise * 0.7 + sub * 0.4) * env * 22000.0, -32000.0, 32000.0))
		samples << val
	}
	sm.play_samples(samples)
}

// Yippee Exit Portal Reached
pub fn (mut sm SoundManager) play_yippee() {
	dur := 0.18
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 600.0 + (t / dur) * 800.0 // Rising pitch
		env := math.sin(math.pi * (t / dur))
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 14000.0)
		samples << val
	}
	sm.play_samples(samples)
}
