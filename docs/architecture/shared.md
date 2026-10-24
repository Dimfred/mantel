# shared

Source: `Sources/mantel/Shared/`

## Responsibility

Process-wide constants.

## Key types / interfaces

- `logger`: `os.Logger`, subsystem `com.dimfred.mantel`, category `general`
- `defaultFifoPath`: `/tmp/mantel.fifo`

## Decisions

- One logger for now; split per category once a domain gets noisy

## Known gaps
