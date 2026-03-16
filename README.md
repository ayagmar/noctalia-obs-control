# OBS Control for Noctalia

OBS Studio controls for Noctalia with:

- a bar indicator while recording
- a Control Center shortcut when OBS is active
- a panel with record and replay actions
- configurable polling, visibility, click behavior, and videos path
- native Noctalia toast actions for opening the videos folder after saves

## Features

- left click can open the control panel or toggle recording
- right click toggles recording
- middle click toggles the replay buffer
- panel includes quick access to the videos folder
- toast action opens the configured videos folder after saves

## Dependencies

- `obs-studio`
- OBS WebSocket enabled in OBS
- `node` available in `PATH`

## Installation
1. Navigate to the Noctalia settings plugins section

2. Open the sources sub-menu

3. Add Obs Control as a custom repository
```bash
https://github.com/ayagmar/noctalia-obs-control.git
```

4. Navigate back to Available plugins and search for Obs Control

5. Click install button

Enable it in Noctalia and add `plugin:obs-control` to your bar or Control Center layout.

## Screenshots

Main panel:

![OBS Control panel](preview.png)

Plugin settings:

![OBS Control settings](settings.png)
