import Foundation
import XCTest

@testable import SnapshotTesting

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class URLRequestTests: BaseTestCase {
  func testURLRequest() async {
    var get = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
    get.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    get.addValue("text/html", forHTTPHeaderField: "Accept")
    get.addValue("application/json", forHTTPHeaderField: "Content-Type")
    await assertSnapshot(of: get, as: .raw, named: "get")
    await assertSnapshot(of: get, as: .curl, named: "get-curl")

    var getWithQuery = URLRequest(
      url: URL(string: "https://www.pointfree.co?key_2=value_2&key_1=value_1&key_3=value_3")!
    )
    getWithQuery.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    getWithQuery.addValue("text/html", forHTTPHeaderField: "Accept")
    getWithQuery.addValue("application/json", forHTTPHeaderField: "Content-Type")
    await assertSnapshot(of: getWithQuery, as: .raw, named: "get-with-query")
    await assertSnapshot(of: getWithQuery, as: .curl, named: "get-with-query-curl")

    var post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
    post.httpMethod = "POST"
    post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
    post.addValue("text/html", forHTTPHeaderField: "Accept")
    post.httpBody = Data("pricing[billing]=monthly&pricing[lane]=individual".utf8)
    await assertSnapshot(of: post, as: .raw, named: "post")
    await assertSnapshot(of: post, as: .curl, named: "post-curl")

    var postWithJSON = URLRequest(
      url: URL(string: "http://dummy.restapiexample.com/api/v1/create")!
    )
    postWithJSON.httpMethod = "POST"
    postWithJSON.addValue("application/json", forHTTPHeaderField: "Content-Type")
    postWithJSON.addValue("application/json", forHTTPHeaderField: "Accept")
    postWithJSON.httpBody = Data(
      "{\"name\":\"tammy134235345235\", \"salary\":0, \"age\":\"tammy133\"}".utf8
    )
    await assertSnapshot(of: postWithJSON, as: .raw, named: "post-with-json")
    await assertSnapshot(of: postWithJSON, as: .curl, named: "post-with-json-curl")

    var head = URLRequest(url: URL(string: "https://www.pointfree.co/")!)
    head.httpMethod = "HEAD"
    head.addValue("pf_session={}", forHTTPHeaderField: "Cookie")
    await assertSnapshot(of: head, as: .raw, named: "head")
    await assertSnapshot(of: head, as: .curl, named: "head-curl")

    post = URLRequest(url: URL(string: "https://www.pointfree.co/subscribe")!)
    post.httpMethod = "POST"
    post.addValue("pf_session={\"user_id\":\"0\"}", forHTTPHeaderField: "Cookie")
    post.addValue("application/json", forHTTPHeaderField: "Accept")
    post.httpBody = Data(
      """
      {"pricing": {"lane": "individual","billing": "monthly"}}
      """.utf8
    )
  }
}
