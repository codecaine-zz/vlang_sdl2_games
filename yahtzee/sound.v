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
	dur := 0.28
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.sin(math.pi * (t / dur))
		noise := (rand.f64() * 2.0 - 1.0)
		rattle := math.sin(2.0 * math.pi * 140.0 * t) * math.sin(2.0 * math.pi * 32.0 * t)
		val := i16((noise * 0.6 + rattle * 0.4) * env * 14000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Dice clatter on felt table
pub fn (mut sm SoundManager) play_dice_clatter() {
	dur := 0.32
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}

	// 4 sharp dice impact clicks
	impact_times := [0.02, 0.07, 0.14, 0.22]

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		mut val := 0.0

		for it in impact_times {
			if t >= it {
				dt := t - it
				env := math.exp(-dt * 90.0)
				freq := 680.0 + math.sin(dt * 300.0) * 150.0
				s := math.sin(2.0 * math.pi * freq * dt)
				noise := (rand.f64() * 2.0 - 1.0) * 0.4
				val += (s + noise) * env * 9000.0
			}
		}
		samples << i16(math.clamp(val, -32000.0, 32000.0))
	}
	sm.play_samples(samples)
}

// Dice hold lock/unlock toggle
pub fn (mut sm SoundManager) play_dice_toggle(held bool) {
	dur := 0.05
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	freq := if held { 880.0 } else { 587.33 }

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		env := math.exp(-t * 60.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 12000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Score recorded chime
pub fn (mut sm SoundManager) play_score_recorded() {
	dur := 0.22
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	notes := [523.25, 659.25, 783.99] // C5, E5, G5

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		n_idx := int(t / (dur / 3.0))
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		local_t := math.fmod(t, dur / 3.0)
		env := math.exp(-local_t * 18.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 13000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// Upper bonus +35 unlocked fanfare
pub fn (mut sm SoundManager) play_bonus_fanfare() {
	dur := 0.45
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	notes := [587.33, 739.99, 880.00, 1174.66] // D5, F#5, A5, D6

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		n_idx := int(t / (dur / 4.0))
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		local_t := math.fmod(t, dur / 4.0)
		env := math.exp(-local_t * 14.0)
		s := math.sin(2.0 * math.pi * freq * t)
		val := i16(s * env * 15000.0)
		samples << val
	}
	sm.play_samples(samples)
}

// YAHTZEE 50 PTS Jackpot Fanfare!
pub fn (mut sm SoundManager) play_yahtzee_fanfare() {
	dur := 0.7
	count := int(audio_sample_rate * dur)
	mut samples := []i16{cap: count}
	notes := [523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98] // C5, E5, G5, C6, E6, G6

	for i in 0 .. count {
		t := f64(i) / f64(audio_sample_rate)
		n_idx := int(t / (dur / 6.0))
		freq := if n_idx < notes.len { notes[n_idx] } else { notes.last() }
		local_t := math.fmod(t, dur / 6.0)
		env := math.exp(-local_t * 12.0)
		s1 := math.sin(2.0 * math.pi * freq * t)
		s2 := math.sin(2.0 * math.pi * (freq * 1.5) * t) * 0.4
		val := i16((s1 + s2) * env * 16000.0)
		samples << val
	}
	sm.play_samples(samples)
}
