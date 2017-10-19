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

protocol FPCardCollectionViewCellDelegate {
  func showProfile(_ author: FPUser)
}

class FPCardCollectionViewCell: MDCCollectionViewCell {
  @IBOutlet weak var authorImageView: UIImageView!
  @IBOutlet weak var authorLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var postImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var likesLabel: UILabel!

  @IBOutlet weak var comment1Label: UILabel!
  @IBOutlet weak var comment2Label: UILabel!
  @IBOutlet weak var comment3Label: UILabel!
  var viewMoreCommentsLabel: UILabel?
  var postAuthor: FPUser!
  var delegate: FPCardCollectionViewCellDelegate?
  var labelConstraints: [NSLayoutConstraint]!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.contentView.autoresizingMask = [UIViewAutoresizing.flexibleHeight]
    let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
    authorImageView.addGestureRecognizer(imageGestureRecognizer)
    let labelGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
    authorLabel.addGestureRecognizer(labelGestureRecognizer)
  }

  override func layoutSubviews() {
    self.layoutIfNeeded()
  }

  func populateContent(author: FPUser, date: Date, imageURL: String, title: String, likes: Int, comments: [FPComment]) {
    postAuthor = author
    UIImage.circleImage(from: author.profilePictureURL, to: authorImageView)
    authorLabel?.text = author.fullname
    dateLabel?.text = MHPrettyDate.prettyDate(from: date, with: MHPrettyDateShortRelativeTime)
    postImageView?.sd_setImage(with: URL.init(string: imageURL), completed: nil)
    titleLabel?.text = title
    likesLabel?.text = "\(likes.description) likes"
    switch comments.count {
    case 0:
      labelConstraints = [postImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)]
      comment1Label.isHidden = true
      comment2Label.isHidden = true
      comment3Label.isHidden = true
    case 1:
      labelConstraints = [postImageView.bottomAnchor.constraint(equalTo: comment1Label.topAnchor),
                      comment1Label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      comment1Label.heightAnchor.constraint(equalToConstant: 100)]
      comment2Label.isHidden = true
      comment3Label.isHidden = true
    case 2:
      labelConstraints = [postImageView.bottomAnchor.constraint(equalTo: comment1Label.topAnchor),
                      comment1Label.bottomAnchor.constraint(equalTo: comment2Label.topAnchor),
                      comment2Label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)]
      comment3Label.isHidden = true
    default:
      labelConstraints = [postImageView.bottomAnchor.constraint(equalTo: comment1Label.topAnchor),
                      comment1Label.bottomAnchor.constraint(equalTo: comment2Label.topAnchor),
                      comment2Label.bottomAnchor.constraint(equalTo: comment3Label.topAnchor),
                      comment3Label.bottomAnchor.constraint(equalTo: self.bottomAnchor)]
    }
    addConstraints(labelConstraints)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    removeConstraints(labelConstraints)
  }


  func profileTapped() {
    delegate?.showProfile(postAuthor)
  }

  var layerClass: AnyClass {
    return MDCShadowLayer.self
  }
}



