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

// Poker Chip bet slide / clatter
pub fn (mut sm SoundManager) play_chip_bet() {
	dur := 0.12
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		clink1 := math.sin(2.0 * math.pi * 2800.0 * t) * math.exp(-45.0 * t) * 0.6
		clink2 := math.sin(2.0 * math.pi * 3600.0 * t) * math.exp(-55.0 * t) * 0.4
		sample := clink1 + clink2
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Card deal slide
pub fn (mut sm SoundManager) play_card_deal() {
	dur := 0.08
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-35.0 * t) * 0.4
		tone := math.sin(2.0 * math.pi * 320.0 * t) * math.exp(-30.0 * t) * 0.4
		sample := noise + tone
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Check knuckle tap
pub fn (mut sm SoundManager) play_check_tap() {
	dur := 0.15
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		k1 := math.sin(2.0 * math.pi * 150.0 * t) * math.exp(-40.0 * t)
		t2 := t - 0.06
		k2 := if t2 > 0.0 { math.sin(2.0 * math.pi * 150.0 * t2) * math.exp(-40.0 * t2) } else { 0.0 }
		sample := (k1 + k2) * 0.6
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// Fold card toss
pub fn (mut sm SoundManager) play_fold() {
	dur := 0.14
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		noise := (rand.f64() * 2.0 - 1.0) * math.exp(-25.0 * t) * 0.5
		samples << i16(noise * 16000.0)
	}
	sm.play_samples(samples)
}

// Pot collection win chime
pub fn (mut sm SoundManager) play_pot_win() {
	dur := 0.70
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		step := int(t * 8.0) % 3
		freq := match step {
			0 { 523.25 } // C5
			1 { 659.25 } // E5
			else { 783.99 } // G5
		}
		decay := 1.0 - (t / dur) * 0.3
		sample := math.sin(2.0 * math.pi * freq * t) * decay * 0.7
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}

// All-In Siren / Alert
pub fn (mut sm SoundManager) play_all_in() {
	dur := 0.60
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i := 0; i < count; i++ {
		t := f64(i) / f64(audio_sample_rate)
		freq := 600.0 + math.sin(2.0 * math.pi * 6.0 * t) * 200.0
		sample := math.sin(2.0 * math.pi * freq * t) * math.exp(-2.0 * t) * 0.6
		samples << i16(sample * 16000.0)
	}
	sm.play_samples(samples)
}
