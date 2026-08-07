# Recording

The record mode decides when a reference is written to disk. Setting it in source — per assertion,
per scope, or with `.snapshotRecord` on a suite — is covered in the README. This describes the two
levers that apply to a whole run.

## What a run does when nothing names a mode

| Where | Mode | Why |
| --- | --- | --- |
| A development machine | `.failed` | A mismatch re-records immediately, so an intended change lands as a diff of the reference file in one run. Git makes it reviewable and revertable. |
| CI | `.never` | A reference recorded on a runner is discarded with the checkout, so recording there would turn a real mismatch into a green run. |

CI is recognized by the conventional `CI` environment variable holding a non-empty value, which is
also available to tests as `Bool.isCI`:

```swift
@Test(.disabled(if: .isCI))
func rendersOnAGPU() async { … }
```

## Overriding it: `SNAPSHOT_RECORD`

`SNAPSHOT_RECORD` names a mode — `all`, `failed`, `missing` or `never` — and wins over both rows
above, so a job can still record a reference for a runtime nobody has locally. A value that is not
one of the four is reported as a test failure rather than ignored.

**How to set it depends on what is running the tests**, and there is one trap:

```sh
# swift test — an ordinary environment variable
SNAPSHOT_RECORD=all swift test

# xcodebuild — must be prefixed with TEST_RUNNER_, which xcodebuild strips
TEST_RUNNER_SNAPSHOT_RECORD=all xcodebuild test -scheme … -destination …

# Xcode — Product ▸ Scheme ▸ Edit Scheme ▸ Test ▸ Arguments ▸ Environment Variables
```

`xcodebuild` does not pass the invoking shell's environment to the test process. A bare
`SNAPSHOT_RECORD=all xcodebuild test …` is silently dropped **on every destination, macOS
included** — this is not a simulator-only quirk, and there is no `-test-env` flag. The run then
falls back to the default, which on a development machine writes. Commit before running snapshot
tests against a destination you have not recorded for.

`TEST_RUNNER_CI` is the same mechanism, and it is why the `test-*` Makefile targets forward it: it
is what makes a CI run read-only.

## Re-recording every reference

```sh
make record-macos
make record-ios
make record-tvos
```

Each is the matching `test-*` target with `TEST_RUNNER_SNAPSHOT_RECORD=all`. Every test fails by
design — `.all` writes without comparing — so what matters is the resulting `git diff`, not the exit
code. Review it before committing.

References are pinned to the OS the machine recorded on, so re-record on the runtime CI uses rather
than whatever is newest locally; the destinations in the Makefile name it.
