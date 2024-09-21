//
//  SceneDelegate.swift
//  MotionAlertApp
//
//  Created by Kai Garcia on 9/21/24.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        // Instantiate the initial view controller using Storyboard ID
        guard let initialViewController = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController else {
            fatalError("ViewController not found in Main.storyboard")
        }

        window?.rootViewController = initialViewController
        window?.makeKeyAndVisible()
    }

    // Implement other UISceneDelegate methods as needed
}
