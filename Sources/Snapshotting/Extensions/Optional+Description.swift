extension Optional {
  var description: String {
    if let value = self {
      return String(describing: value)
    } else {
      return "nil"
    }
  }
}
