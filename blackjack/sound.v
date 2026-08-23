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

// Ceramic casino chip clink
pub fn (mut sm SoundManager) play_chip_clink() {
	dur := 0.07
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		clink := math.sin(2.0 * math.pi * 3100.0 * t) * math.exp(-60.0 * t) * 0.7
		click := math.sin(2.0 * math.pi * 1400.0 * t) * math.exp(-45.0 * t) * 0.5
		sample := clink + click
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Card slide swoosh
pub fn (mut sm SoundManager) play_card_deal() {
	dur := 0.08
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-35.0 * t) * 0.4
		swoosh := math.sin(2.0 * math.pi * (350.0 - t * 1800.0) * t) * 0.5
		sample := noise + swoosh
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Table knuckle double knock (Stand)
pub fn (mut sm SoundManager) play_stand_knock() {
	dur := 0.16
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		k1 := math.sin(2.0 * math.pi * 140.0 * t) * math.exp(-40.0 * t)
		t2 := t - 0.07
		k2 := if t2 > 0.0 { math.sin(2.0 * math.pi * 140.0 * t2) * math.exp(-40.0 * t2) } else { 0.0 }
		sample := (k1 + k2) * 0.7
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Bust low buzz
pub fn (mut sm SoundManager) play_bust() {
	dur := 0.35
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		sq := if math.sin(2.0 * math.pi * 110.0 * t) > 0 { 0.4 } else { -0.4 }
		sample := sq * math.exp(-4.0 * t) * 0.7
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Win payout chime
pub fn (mut sm SoundManager) play_win_payout() {
	dur := 0.45
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		chime1 := math.sin(2.0 * math.pi * 1046.50 * t) * math.exp(-6.0 * t) * 0.5
		chime2 := math.sin(2.0 * math.pi * 1318.51 * t) * math.exp(-6.0 * t) * 0.5
		sample := chime1 + chime2
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Blackjack 21 Trumpet Fanfare
pub fn (mut sm SoundManager) play_blackjack_fanfare() {
	dur := 1.0
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		step := int(t * 6.0) % 4
		freq := match step {
			0 { 587.33 } // D5
			1 { 739.99 } // F#5
			2 { 880.00 } // A5
			else { 1174.66 } // D6
		}
		decay := 1.0 - (t / dur) * 0.25
		sample := math.sin(2.0 * math.pi * freq * t) * decay * 0.7
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}
