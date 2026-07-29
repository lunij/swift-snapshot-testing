import Foundation

/// Compares a value against a reference snapshot on disk.
///
/// This is the heart of snapshotting: it renders `value` with `strategy`, compares the result
/// against the reference at `snapshotURL`, and — depending on `record` — writes a new reference.
/// It reports nothing on its own; the returned ``SnapshotResult`` is the only output, which leaves
/// the caller free to decide how a mismatch should surface.
///
/// - Parameters:
///   - value: A value to compare against a reference.
///   - strategy: A strategy for serializing, deserializing, and comparing values.
///   - snapshotURL: The file holding the reference snapshot. Its enclosing directory is created if
///     it does not already exist.
///   - artifactDirectory: The directory a mismatching snapshot is written to, so that it can be
///     diffed against the reference.
///   - name: An optional description of the snapshot, used to disambiguate failure messages when a
///     value is snapshot several times over.
///   - record: The record mode to use. Defaults to the mode of the current configuration.
///   - isolation: The actor to isolate to.
/// - Returns: The result of the comparison, carrying a failure message if the value did not match
///   its reference, along with any artifacts worth surfacing.
public func compareSnapshot<Value, Format>(
  of value: @autoclosure () throws -> Value,
  as strategy: SnapshotStrategy<Value, Format>,
  against snapshotURL: URL,
  artifactDirectory: URL,
  named name: String? = nil,
  record: SnapshotConfiguration.Record? = nil,
  isolation: isolated (any Actor)? = #isolation
) async -> SnapshotResult {
  let record = record ?? SnapshotConfiguration.current?.record ?? _record
  return await withSnapshotConfiguration(record: record, isolation: isolation) {
    () async -> SnapshotResult in
    var artifacts: [SnapshotArtifact] = []
    do {
      let fileManager = FileManager.default
      try fileManager.createDirectory(
        at: snapshotURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )

      let snapshotValue = try value()
      let diffable = await strategy.snapshot(snapshotValue)

      func recordSnapshot(writeToDisk: Bool) throws {
        let snapshotData = try strategy.serializer.toData(diffable)

        if writeToDisk {
          try snapshotData.write(to: snapshotURL)
        }

        artifacts.append(
          SnapshotArtifact(name: snapshotURL.lastPathComponent, data: snapshotData)
        )
      }

      if record == .all {
        try recordSnapshot(writeToDisk: true)

        return SnapshotResult(
          outcome: .recordModeOn,
          snapshotURL: snapshotURL,
          name: name,
          recorded: true,
          artifacts: artifacts
        )
      }

      guard fileManager.fileExists(atPath: snapshotURL.path) else {
        if record == .never {
          try recordSnapshot(writeToDisk: false)

          return SnapshotResult(
            outcome: .referenceMissing,
            snapshotURL: snapshotURL,
            name: name,
            artifacts: artifacts
          )
        } else {
          try recordSnapshot(writeToDisk: true)

          return SnapshotResult(
            outcome: .referenceRecorded,
            snapshotURL: snapshotURL,
            name: name,
            recorded: true,
            artifacts: artifacts
          )
        }
      }

      let data = try Data(contentsOf: snapshotURL)
      let reference: Format
      do {
        reference = try strategy.serializer.fromData(data)
      } catch {
        return SnapshotResult(
          outcome: .referenceUnreadable(error.localizedDescription),
          snapshotURL: snapshotURL,
          name: name
        )
      }

      guard let failure = try strategy.comparator.diff(reference, diffable) else {
        return SnapshotResult(outcome: .matched, snapshotURL: snapshotURL, name: name)
      }

      try fileManager.createDirectory(at: artifactDirectory, withIntermediateDirectories: true)
      let failedSnapshotURL = artifactDirectory.appending(path: snapshotURL.lastPathComponent)
      try strategy.serializer.toData(diffable).write(to: failedSnapshotURL)

      artifacts.append(contentsOf: failure.artifacts)

      // Resolved here rather than when the message is rendered: the diff tool comes from a task
      // local that has gone out of scope by the time the caller reads the result.
      let diffCommand = (SnapshotConfiguration.current?.diffTool ?? _diffTool)(
        currentFilePath: snapshotURL.path,
        failedFilePath: failedSnapshotURL.path
      )

      if record == .failed {
        try recordSnapshot(writeToDisk: true)
      }

      return SnapshotResult(
        outcome: .mismatched(failure),
        snapshotURL: snapshotURL,
        artifactURL: failedSnapshotURL,
        name: name,
        recorded: record == .failed,
        diffCommand: diffCommand,
        artifacts: artifacts
      )
    } catch {
      return SnapshotResult(
        outcome: .errored(error.localizedDescription),
        snapshotURL: snapshotURL,
        name: name,
        artifacts: artifacts
      )
    }
  }
}
