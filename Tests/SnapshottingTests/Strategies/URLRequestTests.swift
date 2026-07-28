import Foundation
import Snapshotting
import Testing

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
}
