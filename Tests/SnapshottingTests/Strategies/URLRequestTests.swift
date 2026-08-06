import Foundation
import Testing

@testable import Snapshotting

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct URLRequestTests {
  @Test func `GET request`() async {
    var request = URLRequest(url: URL(string: "https://www.example.com/")!)
    request.addValue("session={}", forHTTPHeaderField: "Cookie")
    request.addValue("text/html", forHTTPHeaderField: "Accept")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    await expectSnapshot(of: request, as: .raw, named: "raw")
    await expectSnapshot(of: request, as: .curl, named: "curl")
  }

  @Test func `GET request with query parameters`() async {
    var request = URLRequest(
      url: URL(string: "https://www.example.com?key_2=value_2&key_1=value_1&key_3=value_3")!
    )
    request.addValue("session={}", forHTTPHeaderField: "Cookie")
    request.addValue("text/html", forHTTPHeaderField: "Accept")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    await expectSnapshot(of: request, as: .raw, named: "raw")
    await expectSnapshot(of: request, as: .curl, named: "curl")
  }

  @Test func `POST request`() async {
    var request = URLRequest(url: URL(string: "https://www.example.com/signup")!)
    request.httpMethod = "POST"
    request.addValue("session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
    request.addValue("text/html", forHTTPHeaderField: "Accept")
    request.httpBody = Data("plan[billing]=monthly&plan[tier]=basic".utf8)
    await expectSnapshot(of: request, as: .raw, named: "raw")
    await expectSnapshot(of: request, as: .curl, named: "curl")
  }

  @Test func `POST request with JSON body`() async {
    var request = URLRequest(url: URL(string: "https://api.example.com/v1/users")!)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.httpBody = Data(
      "{\"name\":\"Jane Doe\", \"age\":30, \"role\":\"tester\"}".utf8
    )
    await expectSnapshot(of: request, as: .raw, named: "raw")
    await expectSnapshot(of: request, as: .curl, named: "curl")
  }

  @Test func `HEAD request`() async {
    var request = URLRequest(url: URL(string: "https://www.example.com/")!)
    request.httpMethod = "HEAD"
    request.addValue("session={}", forHTTPHeaderField: "Cookie")
    await expectSnapshot(of: request, as: .raw, named: "raw")
    await expectSnapshot(of: request, as: .curl, named: "curl")
  }

  /// Every recording leads with the URL, so a request without one is refused rather than described
  /// around the hole where the URL should be. Both strategies answer the same way.
  @Test func `a request without a URL is refused`() async {
    var request = URLRequest(url: URL(string: "https://www.example.com/")!)
    request.url = nil

    await #expect(throws: URLRequestDescriptionError.urlMissing) {
      try await SnapshotStrategy<URLRequest, String>.raw.snapshot(request)
    }
    await #expect(throws: URLRequestDescriptionError.urlMissing) {
      try await SnapshotStrategy<URLRequest, String>.curl.snapshot(request)
    }
  }

  /// A body that is not text still gets sent, so it still gets recorded: bytes that will not decode
  /// read as replacement characters rather than taking the whole body out of the recording.
  @Test func `a body that is not text still records`() async throws {
    var request = URLRequest(url: URL(string: "https://www.example.com/upload")!)
    request.httpMethod = "POST"
    request.httpBody = Data([0xFF, 0xFE])

    let curl = try await SnapshotStrategy<URLRequest, String>.curl.snapshot(request)
    let raw = try await SnapshotStrategy<URLRequest, String>.raw.snapshot(request)

    #expect(curl.contains("--data \"\u{FFFD}\u{FFFD}\""))
    #expect(raw.hasSuffix("\n\u{FFFD}\u{FFFD}"))
  }
}
