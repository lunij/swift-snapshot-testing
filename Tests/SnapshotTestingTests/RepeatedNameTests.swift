import Foundation
import Testing

@testable import SnapshotTesting

/// Covers what happens when two snapshots of one test resolve to the same reference.
///
/// The rule is about writing, not about naming: sharing a reference is only meaningless once
/// something records there. The unit cases drive ``Register`` with URLs, because the rule is a
/// function of what the two snapshots do and not of where they live; the assertion cases prove it is
/// wired into `assertSnapshot`, and read committed references so that neither of their snapshots
/// records.
struct RepeatedNameTests {
  private let url = URL(filePath: "/tmp/reference.json")

  @Test func `a name no snapshot has used is not a repeat`() {
    #expect(Register().claim(url, recording: true) == false)
  }

  @Test func `a repeat is refused once an earlier snapshot has recorded`() {
    let register = Register()
    #expect(register.claim(url, recording: true) == false)
    #expect(register.claim(url, recording: false) == true)
  }

  @Test func `a repeat is refused when this snapshot records`() {
    let register = Register()
    #expect(register.claim(url, recording: false) == false)
    #expect(register.claim(url, recording: true) == true)
  }

  // The case the rule exists to allow: both snapshots read the reference and report honestly, so
  // neither can be compared against what the other left behind.
  @Test func `a repeat is allowed while neither snapshot records`() {
    let register = Register()
    #expect(register.claim(url, recording: false) == false)
    #expect(register.claim(url, recording: false) == false)
    #expect(register.claim(url, recording: false) == false)
  }

  // A refused snapshot is never taken, so it must not leave a claim behind that changes what a later
  // one is told.
  @Test func `a refused snapshot does not register as having recorded`() {
    let register = Register()
    #expect(register.claim(url, recording: false) == false)
    #expect(register.claim(url, recording: true) == true)
    #expect(register.claim(url, recording: false) == false)
  }

  // `.failed` records whatever mismatches, so it counts as writing even where — as here — the value
  // matches and nothing is written in the end. The committed reference is what keeps this from
  // recording into the repository.
  @Test func `two assertions resolving to one name are refused`() async {
    let issues = await captureIssues {
      await assertSnapshot(of: 1, as: .json, record: .failed)
      await assertSnapshot(of: 1, as: .json, record: .failed)
    }

    #expect(issues.count == 1)
    #expect(
      issues.first?.message == """
        Two snapshots in this test resolve to 'two-assertions-resolving-to-one-name-are-refused.json', \
        and one of them records to it, so the second would be compared against whatever the first \
        recorded. Give them different names.
        """
    )
    #expect(issues.first?.sourceLocation.fileID == #fileID)
  }

  // A suffix is one more component of the name, not permission to reuse it.
  @Test func `the same suffix does not tell two snapshots apart`() async {
    let issues = await captureIssues {
      await assertSnapshot(of: 1, as: .json, suffixed: "twice", record: .failed)
      await assertSnapshot(of: 1, as: .json, suffixed: "twice", record: .failed)
    }

    #expect(issues.count == 1)
    #expect(
      issues.first?.message.contains(
        "'the-same-suffix-does-not-tell-two-snapshots-apart.twice.json'"
      ) == true
    )
  }
}
