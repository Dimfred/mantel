# T010 FIFO: no lost back-to-back writes

Milestone: M1
Feature: [FIFO](../FEATURES.md#fifo)

## AC

- N clients writing commands back to back (no waiting) → all N handled, in order per client, no `SIGPIPE` on the client
- A single multi-line (pretty-printed) JSON command still works
- Two JSON objects in one write (with or without newline between) → both handled
- Invalid JSON in the stream is skipped, the next object still decodes

## Verify

- New `FifoServerTests`: burst of 50 writes from parallel writers, multi-object write, pretty JSON
- Drop the 200ms sleep in `invalidJsonIsSkippedAndServerKeepsReading`
- Run `make test` 5× in a row green

## Notes

- Cause: reader does open → read to EOF → close. A writer opening between EOF and `close()` attaches to the old fd; after `close()` its write gets `SIGPIPE` (seen as signal 13 in the test runner) or the bytes are discarded
- Fix idea: open the FIFO once with `O_RDWR` (own writer end → never EOF, no reopen gap), read continuously, split the byte stream into top-level JSON values with a small string / escape aware brace-depth scanner (own file + tests), decode each
- POSIX: writes ≤ `PIPE_BUF` (512 on macOS) are atomic, so concurrent small commands don't interleave

## Commits
