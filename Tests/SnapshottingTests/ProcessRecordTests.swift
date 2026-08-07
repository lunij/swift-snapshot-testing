import Snapshotting
import Testing

struct ProcessRecordTests {
  @Test func `records what failed when nothing names a mode`() {
    let process = ProcessRecord(environment: [:], isCI: false)
    #expect(process.record == .failed)
  }

  @Test func `records nothing on CI when nothing names a mode`() {
    let process = ProcessRecord(environment: [:], isCI: true)
    #expect(process.record == .never)
  }

  @Test(arguments: [
    ("all", SnapshotConfiguration.Record.all),
    ("failed", .failed),
    ("missing", .missing),
    ("never", .never)
  ])
  func `the environment variable names a mode`(value: String, expected: SnapshotConfiguration.Record) {
    let process = ProcessRecord(environment: ["SNAPSHOT_RECORD": value], isCI: false)
    #expect(process.record == expected)
  }

  @Test func `the environment variable wins on CI`() {
    // Without this there is no way to record from a job, which is the one thing a runner is for
    // when a reference has to be taken on a runtime nobody has locally.
    let process = ProcessRecord(environment: ["SNAPSHOT_RECORD": "all"], isCI: true)
    #expect(process.record == .all)
  }

  @Test func `an unrecognized value falls back and is reported`() {
    let process = ProcessRecord(environment: ["SNAPSHOT_RECORD": "nver"], isCI: false)
    #expect(process.record == .failed)
    #expect(process.unrecognizedValue == "nver")
    #expect(
      process.warning == """
        'SNAPSHOT_RECORD' is set to 'nver', which is not a record mode, so snapshots are being \
        taken with 'failed'. Valid values are 'all', 'failed', 'missing' and 'never'.
        """
    )
  }

  @Test func `a recognized value is not reported`() {
    let process = ProcessRecord(environment: ["SNAPSHOT_RECORD": "never"], isCI: false)
    #expect(process.unrecognizedValue == nil)
    #expect(process.warning == nil)
  }
}
