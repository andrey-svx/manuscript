import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let newWindow = UIWindow(windowScene: windowScene)
        
        let tabController = UITabBarController()
        
        // Tab 1: UIKit
        let uikitVC = UIKitViewController()
        uikitVC.tabBarItem = UITabBarItem(title: "UIKit", image: UIImage(systemName: "square.grid.2x2"), tag: 0)
        
        // Tab 2: SwiftUI
        let swiftuiVC = SwiftUIHostViewController()
        swiftuiVC.tabBarItem = UITabBarItem(title: "SwiftUI", image: UIImage(systemName: "swift"), tag: 1)
        
        tabController.viewControllers = [uikitVC, swiftuiVC]
        
        newWindow.rootViewController = tabController
        newWindow.makeKeyAndVisible()
        
        self.window = newWindow
    }
}
