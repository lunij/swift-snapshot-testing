#if os(iOS)
import SnapshotTesting
import Testing
import UIKit

// Covers the two plural 'assertSnapshots' overloads, which are wrapper API with no engine
// equivalent. The array overload is also the only remaining exercise of the per-test counter that
// names unnamed snapshots '.1', '.2', … in the order they are taken.
@MainActor
@Suite(.snapshots(record: .failed, diffTool: .ksdiff))
struct AssertSnapshotsTests {
  @Test func `multiple snapshots`() async {
    class TableViewController: UITableViewController {
      override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
      }
      override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10
      }
      override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
      )
        -> UITableViewCell
      {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        return cell
      }
    }
    let tableViewController = TableViewController()
    await assertSnapshots(
      of: tableViewController,
      as: ["iPhoneSE-image": .image(on: .iPhoneSe), "iPad-image": .image(on: .iPadMini)]
    )
    await assertSnapshots(
      of: tableViewController,
      as: [.image(on: .iPhoneX), .image(on: .iPhoneXsMax)]
    )
  }
}
#endif
