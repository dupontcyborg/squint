# Squint

<p align="center">
  <a href="https://github.com/dupontcyborg/squint/releases/latest"><img src="https://img.shields.io/github/v/release/dupontcyborg/squint?label=version&color=orange" alt="Latest release"></a>
  <a href="https://github.com/dupontcyborg/squint/releases/latest"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fsquint.sh%2Fbadge%2Fdmg.json" alt="DMG size"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/dupontcyborg/squint" alt="MIT License"></a>
</p>

<p align="center">
  <img src="Squint/AppIcon.png" width="128" height="128" alt="Squint App Icon">
</p>

<p align="center">
  <b>Squint</b> is a lightweight macOS menu bar utility that lets you temporarily suppress auto-brightness for a chosen duration (e.g., during color-sensitive work, presentations, or in unstable lighting conditions) and automatically restores it when the timer expires.
</p>

<p align="center">
  <a href="https://squint.sh/download">
    <img src="https://img.shields.io/github/v/release/dupontcyborg/squint?label=Download%20Latest%20DMG&color=orange&style=for-the-badge" alt="Download Latest DMG">
  </a>
</p>

## Requirements

macOS 13+ on a Mac with a built-in display or a compatible Apple external display (Studio Display / Pro Display XDR).

## Build

```bash
./build.sh && open build/Squint.app
```

Releases are cut by pushing a `v*` tag (see [RELEASE.md](RELEASE.md)).

## AI Disclosure

This project was built with substantial use of large language models. Specifically:

- Architecture and design: human (me, [@dupontcyborg](https://nico.codes), a senior software engineer).
- Implementation: predominantly LLM-assisted.
- Review: me again.

Bugs and typos are mine, just like the pre-LLM days.

## License

[MIT](LICENSE) © [Nicolas Dupont](https://nico.codes).
