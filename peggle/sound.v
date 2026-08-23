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

// Cannon Shot Pop
pub fn (mut sm SoundManager) play_cannon() {
	dur := 0.12
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	attack_samples := int(audio_sample_rate * 0.002)

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 28.0)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		freq := 340.0 * math.exp(-t * 20.0)
		s := math.sin(2.0 * math.pi * freq * t) + 0.3 * math.sin(4.0 * math.pi * freq * t)
		noise := (rand.f64() * 2.0 - 1.0) * 0.25
		val := i16((s + noise) * env * attack * 20000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Peg Bounce Ding (Ascending Pentatonic Scale)
pub fn (mut sm SoundManager) play_peg_ding(combo int) {
	scale := [523.25, 587.33, 659.25, 783.99, 880.00, 1046.50, 1174.66, 1318.51]
	freq := scale[combo % scale.len]

	dur := 0.15
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	attack_samples := int(audio_sample_rate * 0.002)

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 16.0)
		attack := if i < attack_samples { f64(i) / f64(attack_samples) } else { 1.0 }
		s := math.sin(2.0 * math.pi * freq * t) + 0.35 * math.sin(4.0 * math.pi * freq * t)
		val := i16(s * env * attack * 18000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Bucket Catch Free Ball
pub fn (mut sm SoundManager) play_bucket_catch() {
	dur := 0.28
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	notes := [659.25, 880.00, 1318.51]
	note_dur := dur / f64(notes.len)
	attack_samples := int(audio_sample_rate * 0.002)

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		n_idx := int(t / note_dur)
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		local_t := math.fmod(t, note_dur)
		local_sample := int(local_t * f64(audio_sample_rate))
		attack := if local_sample < attack_samples { f64(local_sample) / f64(attack_samples) } else { 1.0 }
		env := math.exp(-local_t * 14.0)
		s := math.sin(2.0 * math.pi * freq * local_t) + 0.3 * math.sin(4.0 * math.pi * freq * local_t)
		val := i16(s * env * attack * 18000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// EXTREME FEVER Ode to Joy Celebration!
pub fn (mut sm SoundManager) play_fever() {
	dur := 0.9
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	// Ode to Joy opening notes: E5, E5, F5, G5, G5, F5, E5, D5
	notes := [659.25, 659.25, 698.46, 783.99, 783.99, 698.46, 659.25, 587.33]
	note_dur := dur / f64(notes.len)
	attack_samples := int(audio_sample_rate * 0.002)

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		n_idx := int(t / note_dur)
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		local_t := math.fmod(t, note_dur)
		local_sample := int(local_t * f64(audio_sample_rate))
		attack := if local_sample < attack_samples { f64(local_sample) / f64(attack_samples) } else { 1.0 }
		env := math.exp(-local_t * 10.0)
		s1 := math.sin(2.0 * math.pi * freq * local_t)
		s2 := math.sin(2.0 * math.pi * (freq * 2.0) * local_t) * 0.3
		val := i16((s1 + s2) * env * attack * 20000.0)
		samples << val
	}
	sm.play_samples(samples)
}
