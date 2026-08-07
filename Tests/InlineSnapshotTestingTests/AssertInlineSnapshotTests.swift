// swift-format-ignore-file: OnlyOneTrailingClosureArgument

import InlineSnapshotTesting
import SnapshotTesting
import Testing

@Suite(.snapshotRecord(.failed), .snapshotDiffTool(.ksdiff))
struct AssertInlineSnapshotTests {
  @Test func inlineSnapshot() async {
    await assertInlineSnapshot(of: ["Hello", "World"], as: .dump) {
      """
      ▿ 2 elements
        - "Hello"
        - "World"

      """
    }
  }

  @Test func inlineSnapshotFailure() async throws {
    let issues = await captureIssues {
      await assertInlineSnapshot(of: ["Hello", "World"], as: .dump, record: .missing) {
        """
        ▿ 2 elements
          - "Hello"

        """
      }
    }
    #expect(issues.count == 1)
    #expect(
      issues.first?.message == """
        Snapshot did not match. Difference: …

          @@ −1,3 +1,4 @@
           ▿ 2 elements
             - "Hello"
          +  - "World"
           
        """
    )
  }

  @Test func inlineSnapshot_NamedTrailingClosure() async {
    await assertInlineSnapshot(
      of: ["Hello", "World"],
      as: .dump,
      matches: {
        """
        ▿ 2 elements
          - "Hello"
          - "World"

        """
      }
    )
  }

  @Test func inlineSnapshot_Escaping() async {
    await assertInlineSnapshot(of: "Hello\"\"\"#, world", as: .lines) {
      ##"""
      Hello"""#, world
      """##
    }
  }

  @Test func customInlineSnapshot() async {
    await assertCustomInlineSnapshot {
      "Hello"
    } is: {
      """
      - "Hello"

      """
    }
  }

  @Test func customInlineSnapshot_Multiline() async {
    await assertCustomInlineSnapshot {
      """
      "Hello"
      "World"
      """
    } is: {
      #"""
      - "\"Hello\"\n\"World\""

      """#
    }
  }

  @Test func customInlineSnapshot_SingleTrailingClosure() async {
    await assertCustomInlineSnapshot(of: { "Hello" }) {
      """
      - "Hello"

      """
    }
  }

  @Test func customInlineSnapshot_MultilineSingleTrailingClosure() async {
    await assertCustomInlineSnapshot(
      of: { "Hello" }
    ) {
      """
      - "Hello"

      """
    }
  }

  @Test func customInlineSnapshot_NoTrailingClosure() async {
    await assertCustomInlineSnapshot(
      of: { "Hello" },
      is: {
        """
        - "Hello"

        """
      }
    )
  }

  @Test func argumentlessInlineSnapshot() async {
    func assertArgumentlessInlineSnapshot(
      expected: (() -> String)? = nil,
      fileID: StaticString = #fileID,
      filePath: StaticString = #filePath,
      function: StaticString = #function,
      line: UInt = #line,
      column: UInt = #column
    ) async {
      await assertInlineSnapshot(
        of: "Hello",
        as: .dump,
        syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
          trailingClosureLabel: "is",
          trailingClosureOffset: 1
        ),
        matches: expected,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
      )
    }

    await assertArgumentlessInlineSnapshot {
      """
      - "Hello"

      """
    }
  }

  @Test func multipleInlineSnapshots() async {
    func assertResponse(
      of url: () -> String,
      head: (() -> String)? = nil,
      body: (() -> String)? = nil,
      fileID: StaticString = #fileID,
      filePath: StaticString = #filePath,
      function: StaticString = #function,
      line: UInt = #line,
      column: UInt = #column
    ) async {
      await assertInlineSnapshot(
        of: """
          HTTP/1.1 200 OK
          Content-Type: text/html; charset=utf-8
          """,
        as: .lines,
        message: "Head did not match",
        syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
          trailingClosureLabel: "head",
          trailingClosureOffset: 1
        ),
        matches: head,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
      )
      await assertInlineSnapshot(
        of: """
          <!doctype html>
          <html lang="en">
          <head>
            <meta charset="utf-8">
            <title>Example</title>
            <link rel="stylesheet" href="style.css">
          </head>
          <body>
            <p>Hello, world!</p>
          </body>
          </html>
          """,
        as: .lines,
        message: "Body did not match",
        syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
          trailingClosureLabel: "body",
          trailingClosureOffset: 2
        ),
        matches: body,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
      )
    }

    await assertResponse {
      """
      https://www.example.com/
      """
    } head: {
      """
      HTTP/1.1 200 OK
      Content-Type: text/html; charset=utf-8
      """
    } body: {
      """
      <!doctype html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>Example</title>
        <link rel="stylesheet" href="style.css">
      </head>
      <body>
        <p>Hello, world!</p>
      </body>
      </html>
      """
    }
  }

  @Test func asyncThrowing() async throws {
    func assertAsyncThrowingInlineSnapshot(
      of value: () -> String,
      is expected: (() -> String)? = nil,
      fileID: StaticString = #fileID,
      filePath: StaticString = #filePath,
      function: StaticString = #function,
      line: UInt = #line,
      column: UInt = #column
    ) async throws {
      await assertInlineSnapshot(
        of: value(),
        as: .dump,
        syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
          trailingClosureLabel: "is",
          trailingClosureOffset: 1
        ),
        matches: expected,
        fileID: fileID,
        file: filePath,
        function: function,
        line: line,
        column: column
      )
    }

    try await assertAsyncThrowingInlineSnapshot {
      "Hello"
    } is: {
      """
      - "Hello"

      """
    }
  }

  @Test func nestedInClosureFunction() async {
    func withDependencies(operation: () async -> Void) async {
      await operation()
    }

    await withDependencies {
      await assertInlineSnapshot(of: "Hello", as: .dump) {
        """
        - "Hello"

        """
      }
    }
  }

  @Test func carriageReturnInlineSnapshot() async {
    await assertInlineSnapshot(of: "This is a line\r\nAnd this is a line\r\n", as: .lines) {
      """
      This is a line\r
      And this is a line\r

      """
    }
  }

  @Test func carriageReturnRawInlineSnapshot() async {
    await assertInlineSnapshot(of: "\"\"\"#This is a line\r\nAnd this is a line\r\n", as: .lines) {
      ##"""
      """#This is a line\##r
      And this is a line\##r

      """##
    }
  }

  // These tests mutate the global `inlineSnapshotState` and must not run in parallel with each
  // other, so they are grouped in a serialized suite.
  @Suite(.serialized)
  struct RecordFailedTests {
    @Test func recordFailed_IncorrectExpectation() async {
      let initialInlineSnapshotState = inlineSnapshotState.withLock { $0 }
      defer { inlineSnapshotState.withLock { $0 = initialInlineSnapshotState } }

      let issues = await captureIssues {
        await assertInlineSnapshot(of: 42, as: .json) {
          """
          4
          """
        }
      }
      #expect(issues.count == 1)
      #expect(
        issues.first?.message == """
          Snapshot did not match. Difference: …

            @@ −1,1 +1,1 @@
            −4
            +42

          A new snapshot was automatically recorded.
          """
      )

      inlineSnapshotState.withLock { inlineSnapshotState in
        #expect(inlineSnapshotState.count == 1)
        #expect(
          String(describing: inlineSnapshotState.keys.first!.path)
            .hasSuffix("AssertInlineSnapshotTests.swift")
        )
      }
    }

    @Test func recordFailed_MissingExpectation() async {
      let initialInlineSnapshotState = inlineSnapshotState.withLock { $0 }
      defer { inlineSnapshotState.withLock { $0 = initialInlineSnapshotState } }

      let issues = await captureIssues {
        await assertInlineSnapshot(of: 42, as: .json)
      }
      #expect(issues.count == 1)
      #expect(
        issues.first?.message == """
          Automatically recorded a new snapshot. Difference: …

            @@ −1,1 +1,1 @@
            −
            +42

          Re-run "recordFailed_MissingExpectation()" to assert against the newly-recorded snapshot.
          """
      )

      inlineSnapshotState.withLock { inlineSnapshotState in
        #expect(inlineSnapshotState.count == 1)
        #expect(
          String(describing: inlineSnapshotState.keys.first!.path)
            .hasSuffix("AssertInlineSnapshotTests.swift")
        )
      }
    }
  }
}

private func assertCustomInlineSnapshot(
  of value: () -> String,
  is expected: (() -> String)? = nil,
  fileID: StaticString = #fileID,
  filePath: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column
) async {
  await assertInlineSnapshot(
    of: value(),
    as: .dump,
    syntaxDescriptor: InlineSnapshotSyntaxDescriptor(
      trailingClosureLabel: "is",
      trailingClosureOffset: 1
    ),
    matches: expected,
    fileID: fileID,
    file: filePath,
    function: function,
    line: line,
    column: column
  )
}
