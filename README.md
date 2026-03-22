# mac-audio-output-automator

Minimal macOS menu bar utility for switching audio output devices.

## Current status
Clean-slate rebuild complete.
Core menu bar architecture working.

## Structure
- MenuController.swift → menu UI
- AudioController.swift → device switching logic
- Config.swift → device mapping
- MenuBarAudioApp.swift → app entry

## Goal
Fast, zero-friction audio device switching from menu bar.

## Next milestone
Implement real CoreAudio switching logic.
