# force-agy-cli-1m

Use the full context window of Gemini models in the Google Antigravity CLI (`agy`).

## The problem

Gemini models in `agy` have a 1M token window. But `agy` compacts the conversation
at about 256K tokens. In the status line, this shows as a compaction at every ~25%
of context used. You lose exact file content, symbols, and schemas after each one.

The cause is in the binary, not in your config:

1. `SelectorModel.offersContextWindow` shows the `Context` chip in `/model` for Gemini 4 Argon only.
2. `Store.ContextWindow` drops the saved `contextWindow` value for all other models.
3. `cortex/utils.GetCheckpointConfig` clamps the compaction threshold to `256000` (`0x3e800`).

These do not help:

- `"contextWindow": "900K"` in `~/.gemini/antigravity-cli/settings.json` (ignored for non-Argon models)
- `AGY_CLI_AUTO_COMPACT_OVERRIDE` (the env read is compiled out)

Upstream issues: [#1245](https://github.com/google-antigravity/antigravity-cli/issues/1245),
[#878](https://github.com/google-antigravity/antigravity-cli/issues/878),
[#1316](https://github.com/google-antigravity/antigravity-cli/issues/1316),
[#1371](https://github.com/google-antigravity/antigravity-cli/issues/1371).

## The fix

`patch.sh` downloads [LiraNuna's `patch_agy.py`](https://gist.github.com/LiraNuna/4c058aed3f636f5193f920f64284ff26)
at a pinned revision, checks its SHA-256, and runs it. The script finds the three
functions through the Go symbol table and patches them:

| Function | Change |
| --- | --- |
| `offersContextWindow` | returns `true`, so the `Context` chip shows for all models |
| `Store.ContextWindow` | jumps to `Store.ContextWindowChoice`, so your choice reaches the backend |
| `GetCheckpointConfig` | the `256000` clamp is removed |

The script makes a backup at `<agy>.bak` before it writes.

## Usage

```bash
git clone https://github.com/oriastanjung/force-agy-cli-1m
cd force-agy-cli-1m
./patch.sh --dry-run   # check that the binary can be patched
./patch.sh             # patch the agy on your PATH
./patch.sh --restore   # put back the original binary
```

You can also give a path: `./patch.sh ~/.local/bin/agy`.

Then in `agy`: open `/model`, select your model, press Tab on `Context` until it shows `900K`.

## Read before you use it

- **Self-update removes the patch.** Run `./patch.sh` again after each `agy update`.
- **Cost.** `agy` shows `512K 1.3x` and `900K 1.8x` multipliers. Long uncached requests cost more.
- **Quality.** Very long contexts can make answers worse. 256K is a default for a reason.
- **Unofficial.** This changes machine code in a Google binary. Not supported by Google. Use at your own risk.
- **Linux x86-64 only.** Patch applies on `agy` 1.4.12.

## Credits

Patch script by [LiraNuna](https://github.com/LiraNuna), from issue
[#1245](https://github.com/google-antigravity/antigravity-cli/issues/1245).
This repo only pins, checks, and runs it.

## License

`patch.sh` and this README: MIT. `patch_agy.py` is not in this repo and keeps its author's terms.
