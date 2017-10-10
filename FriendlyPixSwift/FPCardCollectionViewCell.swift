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

import UIKit
import MaterialComponents.MaterialCollections
import MHPrettyDate
import SDWebImage

class FPCardCollectionViewCell: MDCCollectionViewCell {
  @IBOutlet weak var authorImageView: UIImageView!
  @IBOutlet weak var authorLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var postImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var likesLabel: UILabel!

  var comment1Label: UILabel?
  var comment2Label: UILabel?
  var comment3Label: UILabel?
  var viewMoreCommentsLabel: UILabel?

  func populateContent(author: String, authorURL: String, date: Date, imageURL: String, title: String, likes: Int) {
    UIImage.circleImage(from: authorURL, to: authorImageView)
    authorLabel?.text = author
    dateLabel?.text = MHPrettyDate.prettyDate(from: date, with: MHPrettyDateShortRelativeTime)
    postImageView?.sd_setImage(with: URL.init(string: imageURL), completed: nil)
    titleLabel?.text = title
    likesLabel?.text = "\(likes.description) likes"
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    //    title = nil
    //    image = nil
    //    thumbnailImageView.setImage(nil)
  }

  var layerClass: AnyClass {
    return MDCShadowLayer.self
  }
}



