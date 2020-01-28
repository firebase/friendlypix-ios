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

import Firebase
import MaterialComponents

extension MDCSelfSizingStereoCell {

  static let attributes = [NSAttributedString.Key.font: UIFont.mdc_preferredFont(forMaterialTextStyle: .body2)]
  static let attributes2 = [NSAttributedString.Key.font: UIFont.mdc_preferredFont(forMaterialTextStyle: .body1)]

  func populateContent(from: FPUser, text: String, date: Date, index: Int) {
    let attrText = NSMutableAttributedString(string: from.fullname , attributes: MDCSelfSizingStereoCell.attributes)
    attrText.append(NSAttributedString(string: " " + text, attributes: MDCSelfSizingStereoCell.attributes2))
    attrText.addAttribute(.paragraphStyle, value: MDCSelfSizingStereoCell.paragraphStyle, range: NSMakeRange(0, attrText.length))
    titleLabel.attributedText = attrText
    titleLabel.accessibilityLabel = "\(from.fullname) said, \(text)"
    if let profilePictureURL = from.profilePictureURL {
      UIImage.circleImage(with: profilePictureURL, to: leadingImageView)
      leadingImageView.accessibilityLabel = from.fullname
      leadingImageView.accessibilityHint = "Double-tap to open profile."
    }
    leadingImageView.tag = index
    titleLabel.tag = index
    detailLabel.text = date.timeAgo()
  }


  static let paragraphStyle = { () -> NSMutableParagraphStyle in
    let style = NSMutableParagraphStyle()
    style.lineSpacing = 2
    return style
  }()
}
