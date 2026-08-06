#if !os(WASI)
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension SnapshotStrategy where Value == URLRequest, Format == String {
  /// A snapshot strategy for comparing requests based on raw equality.
  ///
  /// Records:
  ///
  /// ```
  /// POST http://localhost:8080/account
  /// Cookie: session={"userId":"1"}
  ///
  /// email=blob%40example.com&name=Blob
  /// ```
  public static var raw: SnapshotStrategy {
    SnapshotStrategy.raw(pretty: false)
  }

  /// A snapshot strategy for comparing requests based on raw equality.
  ///
  /// - Parameter pretty: Attempts to pretty print the body of the request (supports JSON).
  public static func raw(pretty: Bool) -> SnapshotStrategy {
    DirectSnapshotStrategy.lines.transform(identifier: "raw") { request in
      guard let url = request.url else { throw URLRequestDescriptionError.urlMissing }

      let method = "\(request.httpMethod ?? "GET") \(url.sortingQueryItems().absoluteString)"

      let headers = (request.allHTTPHeaderFields ?? [:])
        .map { key, value in "\(key): \(value)" }
        .sorted()

      let body =
        request.httpBody
        .map { ["\n\($0.text(prettyPrinted: pretty))"] }
        ?? []

      return ([method] + headers + body).joined(separator: "\n")
    }
  }

  /// A snapshot strategy for comparing requests based on a cURL representation.
  ///
  // Records:
  //
  // ```
  // curl \
  //   --request POST \
  //   --header "Accept: text/html" \
  //   --data 'pricing[billing]=monthly&pricing[lane]=individual' \
  //   "https://www.example.com/subscribe"
  // ```
  public static var curl: SnapshotStrategy {
    DirectSnapshotStrategy.lines.transform(identifier: "curl") { request in
      guard let url = request.url else { throw URLRequestDescriptionError.urlMissing }

      var components = ["curl"]

      // HTTP Method
      let httpMethod = request.httpMethod ?? "GET"
      switch httpMethod {
      case "GET": break
      case "HEAD": components.append("--head")
      default: components.append("--request \(httpMethod)")
      }

      // Headers
      if let headers = request.allHTTPHeaderFields {
        for (field, value) in headers.sorted(by: { $0.key < $1.key }) where field != "Cookie" {
          let escapedValue = value.replacingOccurrences(of: "\"", with: "\\\"")
          components.append("--header \"\(field): \(escapedValue)\"")
        }
      }

      // Body
      if let httpBody = request.httpBody {
        var escapedBody = String(decoding: httpBody, as: UTF8.self)
          .replacingOccurrences(of: "\\\"", with: "\\\\\"")
        escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")

        components.append("--data \"\(escapedBody)\"")
      }

      // Cookies
      if let cookie = request.allHTTPHeaderFields?["Cookie"] {
        let escapedValue = cookie.replacingOccurrences(of: "\"", with: "\\\"")
        components.append("--cookie \"\(escapedValue)\"")
      }

      // URL
      components.append("\"\(url.sortingQueryItems().absoluteString)\"")

      return components.joined(separator: " \\\n\t")
    }
  }
}

extension Data {
  /// The body as text, pretty printed when asked for and when it reads as JSON.
  ///
  /// Not every body is JSON, so one that does not read as JSON quietly records as the bytes that
  /// were sent.
  fileprivate func text(prettyPrinted: Bool) -> String {
    guard prettyPrinted,
      let json = try? JSONSerialization.jsonObject(with: self),
      let prettyPrintedData = try? JSONSerialization.data(
        withJSONObject: json,
        options: [.prettyPrinted, .sortedKeys]
      )
    else {
      return String(decoding: self, as: UTF8.self)
    }

    return String(decoding: prettyPrintedData, as: UTF8.self)
  }
}

extension URL {
  /// The URL with its query items in name order, or the URL as it stands when it cannot be taken
  /// apart and put back together.
  fileprivate func sortingQueryItems() -> URL {
    var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
    let sortedQueryItems = components?.queryItems?.sorted { $0.name < $1.name }
    components?.queryItems = sortedQueryItems

    return components?.url ?? self
  }
}
#endif
