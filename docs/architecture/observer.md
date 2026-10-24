# observer

Source: `Sources/mantel/Observer/`

## Responsibility

Tell `WindowManager` when a terminal window moved / resized or another app got focus.

## Key types / interfaces

- `WindowObserver(pid:onWindowChange:)`: `AXObserver` on the app element for moved, resized, focused-window-changed, main-window-changed; `start()` false when Accessibility is denied (prompts) or the observer can't be created
- `FocusObserver(onFocusChange:)`: `NSWorkspace.didActivateApplicationNotification` → active pid

## Decisions

- Wired only through `WindowEnvironment.live`, so `WindowManager` tests never touch AX / NSWorkspace
- AX C callback bridges via an unretained `self` pointer; the token kept in `WindowManager` keeps it alive

## Known gaps

- No unit tests (AX needs a trusted process + real windows); manual checks in `docs/CHECKLIST.md`
- Accessibility denied → images don't follow terminal moves, no user-visible hint besides the log
