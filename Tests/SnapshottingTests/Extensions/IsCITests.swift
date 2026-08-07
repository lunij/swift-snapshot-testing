import Testing

@testable import Snapshotting

struct IsCITests {
  @Test func `an absent variable is not CI`() {
    #expect(Bool.isCI(in: [:]) == false)
  }

  @Test func `an empty variable is not CI`() {
    #expect(Bool.isCI(in: ["CI": ""]) == false)
  }

  @Test(arguments: ["1", "true", "false", "woodpecker"])
  func `any other value is CI`(value: String) {
    #expect(Bool.isCI(in: ["CI": value]))
  }
}
