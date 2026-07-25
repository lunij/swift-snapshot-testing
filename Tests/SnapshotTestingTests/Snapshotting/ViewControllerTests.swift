import XCTest

@testable import SnapshotTesting

#if canImport(UIKit)
import UIKit
#endif

final class ViewControllerTests: BaseTestCase {
  func testAutolayout() async {
    #if os(iOS)
    let vc = UIViewController()
    vc.view.translatesAutoresizingMaskIntoConstraints = false
    let subview = UIView()
    subview.translatesAutoresizingMaskIntoConstraints = false
    vc.view.addSubview(subview)
    NSLayoutConstraint.activate([
      subview.topAnchor.constraint(equalTo: vc.view.topAnchor),
      subview.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
      subview.leftAnchor.constraint(equalTo: vc.view.leftAnchor),
      subview.rightAnchor.constraint(equalTo: vc.view.rightAnchor)
    ])
    await assertSnapshot(of: vc, as: .image)
    #endif
  }

  func testTableViewController() async {
    #if os(iOS)
    class TableViewController: UITableViewController {
      override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
      }
      override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
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
    await assertSnapshot(of: tableViewController, as: .image(on: .iPhoneSe))
    #endif
  }

  func testAssertMultipleSnapshot() async {
    #if os(iOS)
    class TableViewController: UITableViewController {
      override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
      }
      override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
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
    #endif
  }

  func testCollectionViewsWithMultipleScreenSizes() async {
    #if os(iOS)

    final class CollectionViewController: UIViewController, UICollectionViewDataSource,
      UICollectionViewDelegateFlowLayout
    {

      let flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 20
        return layout
      }()

      lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

      override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(collectionView)

        collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
          collectionView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
          collectionView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
          collectionView.trailingAnchor.constraint(
            equalTo: view.layoutMarginsGuide.trailingAnchor
          ),
          collectionView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        ])

        collectionView.reloadData()

        registerForTraitChanges(
          [UITraitHorizontalSizeClass.self, UITraitVerticalSizeClass.self]
        ) { (self: Self, _: UITraitCollection) in
          self.collectionView.collectionViewLayout.invalidateLayout()
        }
      }

      override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
      }

      func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
      )
        -> UICollectionViewCell
      {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.contentView.backgroundColor = .orange
        return cell
      }

      func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
      )
        -> Int
      {
        return 20
      }

      func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
      ) -> CGSize {
        return CGSize(
          width: min(collectionView.frame.width - 50, 300),
          height: collectionView.frame.height
        )
      }

    }

    let viewController = CollectionViewController()

    await assertSnapshots(
      of: viewController,
      as: [
        "ipad": .image(on: .iPadPro12_9),
        "iphoneSe": .image(on: .iPhoneSe),
        "iphone8": .image(on: .iPhone8),
        "iphoneMax": .image(on: .iPhoneXsMax)
      ]
    )
    #endif
  }

  func testUIViewControllerLifeCycle() async {
    #if os(iOS)
    class ViewController: UIViewController {
      let viewDidLoadExpectation = XCTestExpectation(description: "viewDidLoad")

      let viewWillAppearExpectation = XCTestExpectation(description: "viewWillAppear")
      let viewDidAppearExpectation = XCTestExpectation(description: "viewDidAppear")

      let viewWillDisappearExpectation = XCTestExpectation(description: "viewWillDisappear")
      let viewDidDisappearExpectation = XCTestExpectation(description: "viewDidDisappear")

      override func viewDidLoad() {
        super.viewDidLoad()
        viewDidLoadExpectation.fulfill()
      }
      override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearExpectation.fulfill()
      }
      override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearExpectation.fulfill()
      }
      override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewWillDisappearExpectation.fulfill()
      }
      override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidDisappearExpectation.fulfill()
      }
    }

    let viewController = ViewController()
    viewController.viewWillAppearExpectation.expectedFulfillmentCount = 2
    viewController.viewDidAppearExpectation.expectedFulfillmentCount = 2
    viewController.viewWillDisappearExpectation.expectedFulfillmentCount = 1
    viewController.viewDidDisappearExpectation.expectedFulfillmentCount = 1

    await assertSnapshot(of: viewController, as: .image)

    await fulfillment(
      of: [
        viewController.viewDidLoadExpectation,
        viewController.viewWillAppearExpectation,
        viewController.viewDidAppearExpectation,
        viewController.viewWillDisappearExpectation,
        viewController.viewDidDisappearExpectation
      ],
      enforceOrder: true
    )
    #endif
  }

  func testViewControllerHierarchy() async {
    #if os(iOS)
    let page = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    page.setViewControllers([UIViewController()], direction: .forward, animated: false)
    let tab = UITabBarController()
    tab.viewControllers = [
      UINavigationController(rootViewController: page),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController()),
      UINavigationController(rootViewController: UIViewController())
    ]
    await assertSnapshot(of: tab, as: .hierarchy)
    #endif
  }
}
