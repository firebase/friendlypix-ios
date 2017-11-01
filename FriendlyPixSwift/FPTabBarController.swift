//
//  FPTabBarController.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 10/5/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialAppBar

class FPTabBarController: UITabBarController {
 // let appBar = MDCAppBar()

  override func viewDidLoad() {
    let button = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 36, height: 36))
    button.addTarget(self, action: #selector(clickUser), for: .touchUpInside)
    UIImage.circleButton(from: (FPCurrentUser.shared.user.profilePictureURL), to: button)


    self.navigationController?.navigationBar.items?[0].rightBarButtonItems?.insert(UIBarButtonItem(customView: button), at: 0)
  }

  @objc func clickUser() {
    let x = self.viewControllers?[0] as! FPFeedViewController
    x.clickUser()
  }
}
