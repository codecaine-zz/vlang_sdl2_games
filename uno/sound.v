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
	mut sm := SoundManager{
		enabled: true
	}
	sm.init()
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
	queued := sdl.get_queued_audio_size(sm.dev_id)
	if queued > u32(audio_sample_rate * int(sizeof(i16)) / 4) {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

// Card deal slide swoosh
pub fn (mut sm SoundManager) play_card_deal() {
	dur := 0.09
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-30.0 * t) * 0.4
		swoosh := math.sin(2.0 * math.pi * (400.0 - t * 2500.0) * t) * 0.5
		sample := (noise + swoosh) * 0.6
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Crisp card play snap
pub fn (mut sm SoundManager) play_card_play() {
	dur := 0.08
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		snap := math.sin(2.0 * math.pi * 1800.0 * t) * math.exp(-50.0 * t) * 0.8
		thud := math.sin(2.0 * math.pi * 220.0 * t) * math.exp(-35.0 * t) * 0.5
		sample := snap + thud
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Reverse / Skip special action chime
pub fn (mut sm SoundManager) play_action_chime() {
	dur := 0.25
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		step := int(t * 12.0) % 2
		freq := if step == 0 { 783.99 } else { 1046.50 }
		decay := math.exp(-8.0 * t)
		sample := math.sin(2.0 * math.pi * freq * t) * decay * 0.6
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Dramatic "UNO!" shout chime
pub fn (mut sm SoundManager) play_uno_alert() {
	dur := 0.45
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		tone1 := math.sin(2.0 * math.pi * 880.0 * t) * math.exp(-6.0 * t) * 0.5
		tone2 := math.sin(2.0 * math.pi * 1320.0 * t) * math.exp(-6.0 * t) * 0.5
		sample := tone1 + tone2
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Penalty draw buzz
pub fn (mut sm SoundManager) play_penalty_buzz() {
	dur := 0.30
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		sq := if math.sin(2.0 * math.pi * 130.0 * t) > 0 { 0.4 } else { -0.4 }
		sample := sq * math.exp(-4.0 * t) * 0.7
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Match win celebration fanfare
pub fn (mut sm SoundManager) play_victory_fanfare() {
	dur := 0.90
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		step := int(t * 8.0) % 4
		freq := match step {
			0 { 523.25 } // C5
			1 { 659.25 } // E5
			2 { 783.99 } // G5
			else { 1046.50 } // C6
		}
		decay := 1.0 - (t / dur) * 0.3
		sample := math.sin(2.0 * math.pi * freq * t) * decay * 0.7
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}
