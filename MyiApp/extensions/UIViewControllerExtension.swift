//
//  FindNavigationController.swift
//  MyiApp
//
//  Created by Yung Hak Lee on 5/31/25.
//

import SwiftUI

extension UIViewController {
    func findNavigationController() -> UINavigationController? {
        if let navController = self as? UINavigationController {
            return navController
        }
        for child in children {
            if let navController = child.findNavigationController() {
                return navController
            }
        }
        return nil
    }
}
