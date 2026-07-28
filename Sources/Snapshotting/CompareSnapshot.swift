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
    var attachments: [SnapshotFailure.Artifact] = []
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

        attachments.append(
          SnapshotFailure.Artifact(name: snapshotURL.lastPathComponent, data: snapshotData)
        )
      }

      if record == .all {
        try recordSnapshot(writeToDisk: true)

        return SnapshotResult(
          failure: """
            Record mode is on. Automatically recorded snapshot: …

            open "\(snapshotURL.absoluteString)"

            Turn record mode off and re-run to compare against the newly-recorded snapshot
            """,
          attachments: attachments
        )
      }

      guard fileManager.fileExists(atPath: snapshotURL.path) else {
        if record == .never {
          try recordSnapshot(writeToDisk: false)

          return SnapshotResult(
            failure: """
              No reference was found on disk. New snapshot was not recorded because recording is disabled
              """,
            attachments: attachments
          )
        } else {
          try recordSnapshot(writeToDisk: true)

          return SnapshotResult(
            failure: """
              No reference was found on disk. Automatically recorded snapshot: …

              open "\(snapshotURL.absoluteString)"

              Re-run to compare against the newly-recorded snapshot.
              """,
            attachments: attachments
          )
        }
      }

      let data = try Data(contentsOf: snapshotURL)
      let reference: Format
      do {
        reference = try strategy.serializer.fromData(data)
      } catch {
        return SnapshotResult(
          failure: """
            Couldn't load reference snapshot: \(error.localizedDescription)

            The reference file may be corrupt. Delete it and re-run to record a new one:

            open "\(snapshotURL.absoluteString)"
            """
        )
      }

      guard let failure = try strategy.comparator.diff(reference, diffable) else {
        return SnapshotResult()
      }

      try fileManager.createDirectory(at: artifactDirectory, withIntermediateDirectories: true)
      let failedSnapshotURL = artifactDirectory.appending(path: snapshotURL.lastPathComponent)
      try strategy.serializer.toData(diffable).write(to: failedSnapshotURL)

      attachments.append(contentsOf: failure.artifacts)

      let diffMessage = (SnapshotConfiguration.current?.diffTool ?? _diffTool)(
        currentFilePath: snapshotURL.path,
        failedFilePath: failedSnapshotURL.path
      )

      // The first line is the only line Xcode shows in the issue navigator, so it must carry the
      // specific reason. Everything below it is ordered by decreasing usefulness: failure detail,
      // then file URLs / diff tool command.
      var failureMessage: String
      if let name {
        failureMessage = "[\(name)] \(failure.reason)"
      } else {
        failureMessage = failure.reason
      }

      if record == .failed {
        try recordSnapshot(writeToDisk: true)
        failureMessage += " A new snapshot was automatically recorded."
      }

      if let detail = failure.detail?.trimmingCharacters(in: .whitespacesAndNewlines),
        !detail.isEmpty
      {
        failureMessage += "\n\n\(detail)"
      }

      return SnapshotResult(
        failure: """
          \(failureMessage)

          \(diffMessage)
          """,
        attachments: attachments
      )
    } catch {
      return SnapshotResult(
        failure: "Snapshot failed: \(error.localizedDescription)",
        attachments: attachments
      )
    }
  }
}
