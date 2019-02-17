//
//  Copyright (c) 2017 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import FirebaseUI
import MaterialComponents.MDCTypography

class FPAuthPickerViewController: FUIAuthPickerViewController {
  @IBOutlet var readonlyWarningLabel: UILabel!
  let attributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)]
  let attributes2 = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)]
  var agreed = false

  lazy var disclaimer: MDCAlertController = {
    let alertController = MDCAlertController(title: nil, message: "I understand FriendlyPix is an application aimed at showcasing the Firebase platform capabilities, and should not be used with private or sensitive information. All FriendlyPix data and inactive accounts are regularly removed. I agree to the Terms of Service and Privacy Policy.")

    let acceptAction = MDCAlertAction(title: "I agree", emphasis: .high) { action in
      self.agreed = true
    }
    alertController.addAction(acceptAction)
    let termsAction = MDCAlertAction(title: "Terms") { action in
      UIApplication.shared.open(URL(string: "https://friendly-pix.com/terms")!,
                                options: [:], completionHandler: { completion in
        self.present(alertController, animated: true, completion: nil)
      })
    }
    alertController.addAction(termsAction)
    let policyAction = MDCAlertAction(title: "Privacy") { action in
      UIApplication.shared.open(URL(string: "https://www.google.com/policies/privacy")!,
                                options: [:], completionHandler: { completion in
        self.present(alertController, animated: true, completion: nil)
      })
    }
    alertController.addAction(policyAction)
    let colorScheme = MDCSemanticColorScheme()
    MDCAlertColorThemer.applySemanticColorScheme(colorScheme, to: alertController)
    return alertController
  }()

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if (AppDelegate.euroZone) {
      readonlyWarningLabel.isHidden = false
    }
    if !agreed {
      self.present(disclaimer, animated: true, completion: nil)
    }
  }
}
