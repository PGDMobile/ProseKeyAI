import UIKit
import ProseCore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = buildRootController()
        window.tintColor = .systemBlue
        self.window = window
        window.makeKeyAndVisible()
    }

    private func buildRootController() -> UIViewController {
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [
            UINavigationController(rootViewController: AvailabilityViewController()),
            UINavigationController(rootViewController: CommandsViewController(store: .shared)),
            UINavigationController(rootViewController: PreferencesViewController()),
            UINavigationController(rootViewController: PrivacyViewController())
        ]
        return tabBarController
    }
}
