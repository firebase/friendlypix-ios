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
  var imageConstraint: NSLayoutConstraint?

  override func awakeFromNib() {
    super.awakeFromNib()
    self.contentView.autoresizingMask = [UIViewAutoresizing.flexibleHeight]
    let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
    authorImageView.addGestureRecognizer(imageGestureRecognizer)
    let labelGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileTapped))
    authorLabel.addGestureRecognizer(labelGestureRecognizer)
  }

  func populateContent(author: FPUser, date: Date, imageURL: String, title: String, likes: Int, comments: [FPComment]) {
    postAuthor = author
    UIImage.circleImage(from: author.profilePictureURL, to: authorImageView)
    authorLabel?.text = author.fullname
    dateLabel?.text = MHPrettyDate.prettyDate(from: date, with: MHPrettyDateShortRelativeTime)
    postImageView?.sd_setImage(with: URL(string: imageURL), completed:{ (img, error, cacheType, imageURL) in
      // Handle image being set
      })
    titleLabel?.text = title
    likesLabel?.text = "\(likes.description) likes"

    if labelConstraints != nil {
      NSLayoutConstraint.deactivate(labelConstraints)
      labelConstraints = nil
    }

    let betweenConstant:CGFloat = 1.0
    let bottomConstant:CGFloat = -5.0
    switch comments.count {
    case 0:
      labelConstraints = [postImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -1 / UIScreen.main.scale)]
      comment1Label.isHidden = true
      comment2Label.isHidden = true
      comment3Label.isHidden = true
    case 1:
      labelConstraints = [comment1Label.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: betweenConstant),
                      comment1Label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: bottomConstant)]
      comment2Label.isHidden = true
      comment3Label.isHidden = true
    case 2:
      labelConstraints = [comment1Label.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: betweenConstant),
                      comment2Label.topAnchor.constraint(equalTo: comment1Label.bottomAnchor, constant: betweenConstant),
                      comment2Label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: bottomConstant)]
      comment3Label.isHidden = true
    default:
      labelConstraints = [postImageView.bottomAnchor.constraint(equalTo: comment1Label.topAnchor, constant: betweenConstant),
                          comment2Label.topAnchor.constraint(equalTo: comment1Label.bottomAnchor, constant: betweenConstant),
                      comment3Label.topAnchor.constraint(equalTo: comment2Label.bottomAnchor, constant: betweenConstant),
                      comment3Label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: bottomConstant)]
    }
    NSLayoutConstraint.activate(labelConstraints)
  }

  override func updateConstraints() {
    super .updateConstraints()

    let constant = self.bounds.width * 0.75
    if imageConstraint == nil {
      imageConstraint = postImageView.heightAnchor.constraint(equalToConstant: constant)
      imageConstraint?.isActive = true
    }
    imageConstraint?.constant = constant
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    NSLayoutConstraint.deactivate(labelConstraints)
    labelConstraints = nil
  }

  func profileTapped() {
    delegate?.showProfile(postAuthor)
  }

  var layerClass: AnyClass {
    return MDCShadowLayer.self
  }
}



