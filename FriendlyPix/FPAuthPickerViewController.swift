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

import FirebaseAuthUI

class FPAuthPickerViewController: FUIAuthPickerViewController {
  let attributes = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)]
  let attributes2 = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption2)]

  override func viewDidLoad() {
    super.viewDidLoad()
    let text = NSMutableAttributedString(string: "By signing up, you agree to our Terms & Privacy Policy." , attributes: attributes2)
    text.addAttribute(NSAttributedStringKey.font, value: UIFont.preferredFont(forTextStyle: .caption1), range: NSRange(location: 32,
                                                                                                                                length: 5))
    text.addAttribute(NSAttributedStringKey.font, value: UIFont.preferredFont(forTextStyle: .caption1), range: NSRange(location: 40,
                                                                                                                                length: 14))
    policyTermsLabel.attributedText = text
  }
  @IBOutlet weak var policyTermsLabel: UILabel!
  @IBAction func didTapTermsPolicy(_ sender: UITapGestureRecognizer) {
    if sender.didTapAttributedTextInLabel(label: policyTermsLabel,
                                              inRange: NSRange(location: 32,
                                                               length: 5)) {
      UIApplication.shared.open(URL(string: "https://friendly-pix.com/terms")!, options: [:], completionHandler: nil)
    } else if sender.didTapAttributedTextInLabel(label: policyTermsLabel,
                                                 inRange: NSRange(location: 40,
                                                                  length: 14)) {
      UIApplication.shared.open(URL(string: "https://www.google.com/policies/privacy")!, options: [:], completionHandler: nil)
    }
    
  }
}
