import UIKit
import SwiftUI

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let uikitVC = UIKitTransferViewController()
        let uikitNav = UINavigationController(rootViewController: uikitVC)
        uikitNav.tabBarItem = UITabBarItem(title: "UIKit", image: UIImage(systemName: "square.grid.2x2"), tag: 0)

        let swiftuiView = SwiftUITransferView()
        let swiftuiVC = UIHostingController(rootView: swiftuiView)
        swiftuiVC.tabBarItem = UITabBarItem(title: "SwiftUI", image: UIImage(systemName: "swift"), tag: 1)

        viewControllers = [uikitNav, swiftuiVC]
    }
}
