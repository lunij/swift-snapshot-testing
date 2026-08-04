import Snapshotting
import Testing

struct SnapshotStrategyTests {
  private struct Person { let age: Int }

  @Test func `transforms with a synchronous function`() async throws {
    let strategy: SnapshotStrategy<Person, String> = SnapshotStrategy<Int, String>.description
      .transform { $0.age }

    let output = try await strategy.snapshot(Person(age: 42))
    #expect(output == "42")
  }

  @Test func `transforms with an asynchronous function`() async throws {
    let strategy = SnapshotStrategy<Int, String>.description
      .transform(to: Person.self) { person async in
        await Task { person.age }.value
      }

    let output = try await strategy.snapshot(Person(age: 42))
    #expect(output == "42")
  }

  @Test func `carries the path extension over`() {
    let strategy = SnapshotStrategy<[String: Int], String>.json
      .transform(to: Person.self) { ["age": $0.age] }

    #expect(strategy.pathExtension == "json")
  }
}
