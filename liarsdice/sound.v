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
	if queued > u32(audio_sample_rate * int(sizeof(i16)) / 4) {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

// Cup shaking rattle
pub fn (mut sm SoundManager) play_cup_shake() {
	dur := 0.35
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.sin(t / dur * math.pi)
		noise := (rand.f64() * 2.0 - 1.0) * 0.5
		impact := if i % 1800 < 300 { math.sin(t * 1200.0) * 0.5 } else { 0.0 }
		s := (noise + impact) * env * 14000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Dice slam / reveal
pub fn (mut sm SoundManager) play_slam() {
	dur := 0.18
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 24.0)
		s := math.sin(t * 180.0 * 2.0 * math.pi) * env * 22000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Bid placed click / ding
pub fn (mut sm SoundManager) play_bid() {
	dur := 0.12
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 25.0)
		s := math.sin(t * 880.0 * 2.0 * math.pi) * env * 16000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Dramatic challenge sound (horn / gong)
pub fn (mut sm SoundManager) play_challenge() {
	dur := 0.5
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 5.0)
		s := (math.sin(t * 220.0 * 2.0 * math.pi) + 0.5 * math.sin(t * 277.18 * 2.0 * math.pi)) * env * 18000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Spot On! victory chime
pub fn (mut sm SoundManager) play_spot_on() {
	dur := 0.6
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := if t < 0.2 { 523.25 } else if t < 0.4 { 659.25 } else { 783.99 }
		env := math.exp(-math.fmod(t, 0.2) * 10.0)
		s := math.sin(t * freq * 2.0 * math.pi) * env * 18000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Wrong / Liar caught buzzer
pub fn (mut sm SoundManager) play_buzzer() {
	dur := 0.35
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 6.0)
		s := (if (int(t * 140.0) % 2) == 0 { 1.0 } else { -1.0 }) * env * 16000.0
		samples << i16(math.clamp(s, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}
