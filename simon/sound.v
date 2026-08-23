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

pub fn (mut sm SoundManager) toggle_sound() {
	sm.enabled = !sm.enabled
}

fn (mut sm SoundManager) play_samples(samples []i16) {
	if !sm.enabled || sm.dev_id == 0 || samples.len == 0 {
		return
	}
	sdl.queue_audio(sm.dev_id, samples.data, u32(samples.len * int(sizeof(i16))))
}

pub fn (mut sm SoundManager) play_pad_tone(pad_idx int, dur f64) {
	freqs := [415.3, 311.1, 252.0, 209.3] // G#4, D#4, B3, G#3 (Authentic Simon frequencies)
	f := if pad_idx >= 0 && pad_idx < freqs.len { freqs[pad_idx] } else { 440.0 }
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := if t < 0.01 { t / 0.01 } else if t > dur - 0.02 { (dur - t) / 0.02 } else { 1.0 }
		// Harmonic rich tone (sine + soft 2nd harmonic)
		val := i16((math.sin(2.0 * math.pi * f * t) * 0.85 + math.sin(4.0 * math.pi * f * t) * 0.15) * env * 18000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_error_buzzer() {
	dur := 0.65
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	f := 42.0 // Low harsh sawtooth buzz

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := 1.0 - (t / dur)
		phase := math.fmod(f * t, 1.0)
		val := i16((phase - 0.5) * 2.0 * env * 22000.0)
		samples << val
	}
	sm.play_samples(samples)
}

pub fn (mut sm SoundManager) play_victory_jingle() {
	notes := [523.25, 659.25, 783.99, 1046.5] // C5, E5, G5, C6
	note_dur := 0.1
	count := int(audio_sample_rate * note_dur * f64(notes.len))
	mut samples := []i16{cap: count}

	for _, freq in notes {
		n_count := int(audio_sample_rate * note_dur)
		for i in 0 .. n_count {
			t := f64(i) / f64(audio_sample_rate)
			env := 1.0 - (t / note_dur) * 0.4
			val := i16(math.sin(2.0 * math.pi * freq * t) * env * 16000.0)
			samples << val
		}
	}
	sm.play_samples(samples)
}
