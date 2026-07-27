extension SnapshotStrategy where Value: CaseIterable, Format == String {
  /// A strategy for snapshotting the output for every input of a function. The format of the
  /// snapshot is a comma-separated value (CSV) file that shows the mapping of inputs to outputs.
  ///
  /// - Parameter witness: A snapshotting value on the output of the function to be snapshot.
  /// - Returns: A snapshot strategy on functions `(Value) -> A` that feeds every possible input
  ///   into the function and records the output into a CSV file.
  ///
  /// ```swift
  /// enum Direction: String, CaseIterable {
  ///   case up, down, left, right
  ///   var rotatedLeft: Direction {
  ///     switch self {
  ///     case .up:    return .left
  ///     case .down:  return .right
  ///     case .left:  return .down
  ///     case .right: return .up
  ///     }
  ///   }
  /// }
  ///
  /// assertSnapshot(
  ///   of: \Direction.rotatedLeft,
  ///   as: .func(into: .description)
  /// )
  /// ```
  ///
  /// Records:
  ///
  /// ```csv
  /// "up","left"
  /// "down","right"
  /// "left","down"
  /// "right","up"
  /// ```
  public static func `func`<A>(
    into witness: SnapshotStrategy<A, Format>
  ) -> SnapshotStrategy<(Value) -> A, Format> {
    var strategy = SnapshotStrategy<String, String>.lines.asyncPullback {
      (f: @escaping (Value) -> A) async -> String in
      var rows: [String] = []
      for input in Value.allCases {
        let output = await witness.snapshot(f(input))
        rows.append("\"\(input)\",\"\(output)\"")
      }
      return rows.joined(separator: "\n")
    }
    strategy.pathExtension = "csv"
    return strategy
  }
}
