# ☕ awake

A plugin of [Lokyr](https://lokyr.dev): keeps the Mac awake from a button
beside the window's buttons, always, or while a tab runs a program, as a
long build, a download or an agent's work wants.

## Use

The button beside the window's buttons shows the mode, and opens its menu:

- **Default**, a closed eye: the Mac sleeps as the system's settings say.
- **Stay Awake**, a steaming cup: the Mac and its display stay awake.
- **Sleep After Jobs**, a pulse: the Mac stays awake while a tab runs a
  program other than its shell, the cup showing then, and sleeps as usual
  once the last one ends; its display may sleep meanwhile.

The cup is in the accent color while the Mac is kept awake. The same modes
are in View › Awake, the one in force ticked, and are commands for the
command palette (⇧⌘P) and keys of your own: **Sleep as Usual**
(`awake.default`), **Stay Awake** (`awake.stay`) and **Sleep After Jobs**
(`awake.after-jobs`). Every launch of Lokyr starts in Default, so that a
Mac never stays awake by surprise after a restart.

The Mac sleeps as usual again as Lokyr quits, or as the plugin is turned
off or removed: Lokyr holds the system's power assertion for it, which
`pmset -g assertions` lists as "Lokyr, kept awake by sephiroth74/awake".

## Install

```sh
sleip add sephiroth74/awake
```

## Capabilities

- `keep-awake`, of a high risk, to keep the system, or the system and the
  display, from idle sleep: a display kept awake keeps the screen from
  locking, and costs the battery.
- `process-read`, for the tabs' marks of a program that runs, which Sleep
  After Jobs follows, of no polling.

## Develop

`sleip check` checks the plugin, `sleip test` runs its tests, and
`sleip dev` links it into Lokyr, which reloads it at each save.

## License

MIT, see [LICENSE](LICENSE).
