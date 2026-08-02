#if os(iOS) || os(tvOS)
import Snapshotting
import Testing
import UIKit

@MainActor
struct ViewControllerTests {
  @Test func `auto layout`() async {
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
    await expectSnapshot(of: vc, as: .image, named: platform)
  }

  @Test func `view controller lifecycle`() async {
    class ViewController: UIViewController {
      var lifecycleEvents: [String] = []

      override func viewDidLoad() {
        super.viewDidLoad()
        lifecycleEvents.append("viewDidLoad")
      }
      override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifecycleEvents.append("viewWillAppear")
      }
      override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lifecycleEvents.append("viewDidAppear")
      }
      override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lifecycleEvents.append("viewWillDisappear")
      }
      override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lifecycleEvents.append("viewDidDisappear")
      }
    }

    let viewController = ViewController()

    await expectSnapshot(of: viewController, as: .image, named: platform)

    #expect(
      viewController.lifecycleEvents == [
        "viewDidLoad",
        "viewWillAppear",
        "viewDidAppear",
        "viewWillAppear",
        "viewDidAppear",
        "viewWillDisappear",
        "viewDidDisappear"
      ]
    )
  }

  @Test func `view controller hierarchy`() async {
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
    // The hierarchy is controller classes and their states, with no geometry in it, so iOS and
    // tvOS share one reference. A platform that starts embedding differently should fail here.
    await expectSnapshot(of: tab, as: .hierarchy)
  }

  #if os(iOS)

  // MARK: - Named device screens
  //
  // `DeviceProfile` describes iPhone and iPad screens only, and an Apple TV has a single screen, so
  // laying a view controller out on a named screen — and comparing several of them — is iOS-only.

  @Test func `table view controller`() async {
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
    await expectSnapshot(of: tableViewController, as: .image(on: .iPhone(.year2014)))
  }

  @Test func `collection views with multiple screen sizes`() async {
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
        20
      }

      func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
      ) -> CGSize {
        CGSize(
          width: min(collectionView.frame.width - 50, 300),
          height: collectionView.frame.height
        )
      }

    }

    let viewController = CollectionViewController()

    await expectSnapshot(of: viewController, as: .image(on: .iPad(.year2018Large)), named: "ipad")
    await expectSnapshot(of: viewController, as: .image(on: .iPhone(.year2014)), named: "iphoneSe")
    await expectSnapshot(
      of: viewController,
      as: .image(on: .iPhone(.year2018Max)),
      named: "iphoneMax"
    )
  }
  #endif
}
#endif
