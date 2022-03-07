//
//  DeltaNavigationController.swift
//  Delta
//
//  Created by matrixme on 2022/3/7.
//  Copyright © 2022 Riley Testut. All rights reserved.
//

import Foundation
import UIKit


extension UIDevice {
    static var isNotchScreen: Bool {
        guard #available(iOS 11.0, *), let topPadding = UIApplication.shared.keyWindow?.safeAreaInsets.top, topPadding > 24 else {
            return false
        }
        return true
    }
}

class DeltaNavigationController: UINavigationController {
    private let blureffectview = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13, *) {
            blureffectview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.insertSubview(blureffectview, belowSubview: self.navigationBar)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let rect = navigationBar.frame
        let width = rect.width
        let height = rect.height + 44 + (UIDevice.isNotchScreen ? 44.0: 0.0)
        blureffectview.frame = CGRect(origin: .zero,
                                      size: .init(width: width, height: height))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

