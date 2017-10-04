//
//  FPFeedPhotoCell.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 9/29/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialCollections
import MHPrettyDate

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
    authorImageView?.loadImageUsingCache(withUrl: authorURL)
    authorLabel?.text = author
    dateLabel?.text = MHPrettyDate.prettyDate(from: date, with: MHPrettyDateShortRelativeTime)
    postImageView?.loadImageUsingCache(withUrl: imageURL)
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



