# mantel

Terminal image overlay daemon for macOS.
Draws images in native borderless windows positioned over a terminal, in terminal cells, kept just above that terminal window.

## Install

```bash
brew install dimfred/tap/mantel
brew services start mantel   # LaunchAgent, started now and at login

brew services stop mantel    # before uninstalling, removes the LaunchAgent
brew uninstall mantel
```

From source:

```bash
make install    # binary to /usr/local/bin + LaunchAgent (needs sudo)
make uninstall
```

Grant Accessibility to `mantel` (prompted on first image) so images follow terminal moves / resizes.

## Usage

Write one JSON command per write to `/tmp/mantel.fifo`:

```bash
echo '{"action":"add","identifier":"preview","terminal_pid":'$$',"path":"/abs/img.png","x":2,"y":2,"width":40,"height":12,"cols":'$(tput cols)',"rows":'$(tput lines)'}' > /tmp/mantel.fifo
echo '{"action":"hide","identifier":"preview"}' > /tmp/mantel.fifo
```

Actions: `add`, `remove`, `hide`, `show`, `toggle`, `clear`.
`terminal_pid` may be the shell or any descendant of the terminal.
Full behavior: `docs/FEATURES.md`.

## Develop

```bash
make help       # all targets
make check      # lint + docs-lint + test
make dev        # run locally
make hooks      # pre-commit hook running make check
```

Built with the auto-loop workflow (`CLAUDE.md`, `docs/`).
