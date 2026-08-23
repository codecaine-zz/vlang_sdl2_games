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

// Cash Transaction Ka-Ching
pub fn (mut sm SoundManager) play_cash() {
	dur := 0.18
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := if t < 0.08 { 1318.51 } else { 1760.00 }
		env := math.exp(-math.fmod(t, 0.08) * 22.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 14000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Subway Transit Rumble
pub fn (mut sm SoundManager) play_subway() {
	dur := 0.35
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.sin(math.pi * (t / dur))
		noise := (rand.f64() * 2.0 - 1.0)
		rumble := math.sin(2.0 * math.pi * 95.0 * t)
		val := i16((noise * 0.5 + rumble * 0.5) * env * 15000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Police Siren Alert
pub fn (mut sm SoundManager) play_siren() {
	dur := 0.4
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		freq := 600.0 + math.sin(2.0 * math.pi * 4.0 * t) * 250.0
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * 13000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Gunshot
pub fn (mut sm SoundManager) play_gunshot() {
	dur := 0.2
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 24.0)
		noise := (rand.f64() * 2.0 - 1.0)
		val := i16(noise * env * 22000.0)
		samples << val
	}
	sm.play_samples(samples)
}
