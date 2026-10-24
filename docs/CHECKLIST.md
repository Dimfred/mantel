# Checklist

Manual / visual checks for `[?]` tasks.
Mark `[x]` ok, `[!]` broken (add a note below the item), leave `[ ]` untested.
Notes free-form anywhere.

Start: `make run` in one terminal (stop the LaunchAgent first: `launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.dimfred.mantel.plist`).
In another terminal (Accessibility allowed for the binary / terminal):

```bash
send() { echo "$1" > /tmp/mantel.fifo; }
send "{\"action\":\"add\",\"identifier\":\"t\",\"terminal_pid\":$$,\"path\":\"$PWD/data/test.png\",\"x\":2,\"y\":2,\"width\":30,\"height\":10,\"cols\":$(tput cols),\"rows\":$(tput lines)}"
send '{"action":"hide","identifier":"t"}'
```

## T005 Visibility keeps z-order

- [ ] `add` → image at col 2 / row 2 of this terminal, clicks pass through
- [ ] Put another app's window half over the terminal, `hide` then `show` → image stays under that window (above terminal only)
- [ ] `toggle` twice → same as above
- [ ] `hide`, move + resize the terminal, `show` → image at the new position; stays hidden while moving
- [ ] `remove`, then `show` and `toggle` → nothing appears
- [ ] `hide`, click another app then back to the terminal → image stays hidden
- [ ] `add` with `"cols":0` → nothing appears, log shows `Invalid frame`
