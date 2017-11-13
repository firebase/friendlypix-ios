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

import MaterialComponents
import MHPrettyDate
import SDWebImage

protocol FPCardCollectionViewCellDelegate: class {
  func showProfile(_ author: FPUser)
  func viewComments(_ post: FPPost)
  func toogleLike(_ post: FPPost, button: UIButton, label: UILabel)
}

class FPCardCollectionViewCell: MDCCollectionViewCell {
  @IBOutlet weak private var authorImageView: UIImageView!
  @IBOutlet weak private var authorLabel: UILabel!
  @IBOutlet weak private var dateLabel: UILabel!
  @IBOutlet weak private var postImageView: UIImageView!
  @IBOutlet weak private var titleLabel: UILabel!
  @IBOutlet weak private var likesLabel: UILabel!
  @IBOutlet weak private var likeButton: UIButton!

  @IBOutlet weak private var comment1Label: UILabel!
  @IBOutlet weak private var comment2Label: UILabel!
  @IBOutlet weak private var comment3Label: UILabel!
  @IBOutlet weak private var viewAllCommentsLabel: UIButton!
  var commentLabels: [UILabel]?
  let attributes: [String: UIFont] = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)]

  var post: FPPost!
  weak var delegate: FPCardCollectionViewCellDelegate?
  var labelConstraints: [NSLayoutConstraint]!
  public var imageConstraint: NSLayoutConstraint?

  override func awakeFromNib() {
    super.awakeFromNib()

    authorImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))
    authorLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))
    commentLabels = [comment1Label, comment2Label, comment3Label]

    comment1Label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                              action: #selector(handleTapOnComment(recognizer:))))
    comment2Label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                              action: #selector(handleTapOnComment(recognizer:))))
    comment3Label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                              action: #selector(handleTapOnComment(recognizer:))))
  }

  func populateContent(post: FPPost, isDryRun: Bool) {
    self.post = post
    let postAuthor = post.author!
    if !isDryRun, let profilePictureURL = postAuthor.profilePictureURL {
      UIImage.circleImage(with: profilePictureURL, to: authorImageView)
    }
    authorLabel?.text = postAuthor.fullname
    dateLabel?.text = MHPrettyDate.prettyDate(from: post.postDate, with: MHPrettyDateShortRelativeTime)
    if !isDryRun {
      postImageView?.sd_setImage(with: post.imageURL, completed: nil)
    }

    let title = NSMutableAttributedString(string: postAuthor.fullname, attributes: attributes)
    title.append(NSAttributedString(string: " " + post.text))
    titleLabel?.attributedText = title

    titleLabel?.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                            action: #selector(handleTapOnProfileLabel(recognizer:))))
    likesLabel?.text = "\(post.likeCount) likes"
    if post.isLiked {
      likeButton.setImage(#imageLiteral(resourceName: "ic_favorite"), for: .normal)
    } else {
      likeButton.setImage(#imageLiteral(resourceName: "ic_favorite_border"), for: .normal)
    }

    if labelConstraints != nil {
      NSLayoutConstraint.deactivate(labelConstraints)
      labelConstraints = nil
    }

    let betweenConstant: CGFloat = 1.0
    let bottomConstant: CGFloat = -8
    let commentCount = post.comments.count
    switch commentCount {
    case 0:
      labelConstraints = [titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: bottomConstant)]
      viewAllCommentsLabel.isHidden = true
      comment1Label.isHidden = true
      comment1Label.text = nil
      comment2Label.isHidden = true
      comment2Label.text = nil
      comment3Label.isHidden = true
      comment3Label.text = nil
    case 1:
      labelConstraints = [comment1Label.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                             constant: betweenConstant),
                      comment1Label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                            constant: bottomConstant)]
      viewAllCommentsLabel.isHidden = true
      attributeComment(index: 0)
      comment2Label.isHidden = true
      comment2Label.text = nil
      comment3Label.isHidden = true
      comment3Label.text = nil
    case 2:
      labelConstraints = [comment1Label.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                             constant: betweenConstant),
                      comment2Label.topAnchor.constraint(equalTo: comment1Label.bottomAnchor,
                                                         constant: betweenConstant),
                      comment2Label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                            constant: bottomConstant)]
      viewAllCommentsLabel.isHidden = true
      attributeComment(index: 0)
      attributeComment(index: 1)
      comment3Label.isHidden = true
      comment3Label.text = nil
    default:
      labelConstraints = [titleLabel.bottomAnchor.constraint(equalTo: viewAllCommentsLabel.topAnchor,
                                                             constant: betweenConstant),
                          viewAllCommentsLabel.bottomAnchor.constraint(equalTo: comment1Label.topAnchor,
                                                                       constant: betweenConstant),
                          comment2Label.topAnchor.constraint(equalTo: comment1Label.bottomAnchor,
                                                             constant: betweenConstant),
                      comment3Label.topAnchor.constraint(equalTo: comment2Label.bottomAnchor,
                                                         constant: betweenConstant),
                      comment3Label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                            constant: bottomConstant)]
      viewAllCommentsLabel.isHidden = false
      viewAllCommentsLabel.setTitle("View all \(commentCount) comments", for: .normal)
      attributeComment(index: 0)
      attributeComment(index: 1)
      attributeComment(index: 2)
    }
    NSLayoutConstraint.activate(labelConstraints)
  }

  private func attributeComment(index: Int) {
    if let commentLabel = commentLabels?[index] {
      let comment = post.comments[index]
      commentLabel.isHidden = false
      let text = NSMutableAttributedString(string: comment.from!.fullname, attributes: attributes)
      text.append(NSAttributedString(string: " " + comment.text))
      commentLabel.attributedText = text
    }
  }

  override func updateConstraints() {
    super.updateConstraints()

    let constant = MDCCeil((self.bounds.width - 2) * 0.65)
    if imageConstraint == nil {
      imageConstraint = postImageView.heightAnchor.constraint(equalToConstant: constant)

      imageConstraint?.isActive = true
    }
    imageConstraint?.constant = constant
  }

  @IBAction func toggledLike() {
    delegate?.toogleLike(post, button: likeButton, label: likesLabel)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    NSLayoutConstraint.deactivate(labelConstraints)
    labelConstraints = nil
  }

  func profileTapped() {
    delegate?.showProfile(post.author!)
  }

  func handleTapOnProfileLabel(recognizer: UITapGestureRecognizer) {
    if recognizer.didTapAttributedTextInLabel(label: titleLabel,
                                              inRange: NSRange(location: 0,
                                                               length: post.author.fullname.characters.count)) {
      profileTapped()
    }
  }

  func handleTapOnComment(recognizer: UITapGestureRecognizer) {
    if let index = recognizer.view?.tag, let from = post.comments[index].from,
      recognizer.didTapAttributedTextInLabel(label: commentLabels![index],
                                             inRange: NSRange(location: 0,
                                                              length: from.fullname.characters.count)) {
      delegate?.showProfile(from)
    }
  }

  @IBAction func viewAllComments(_ sender: Any) {
    delegate?.viewComments(post)
  }

  var layerClass: AnyClass {
    return MDCShadowLayer.self
  }
}

extension UITapGestureRecognizer {

  func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
    // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
    let layoutManager = NSLayoutManager()
    let textContainer = NSTextContainer(size: CGSize.zero)
    let textStorage = NSTextStorage(attributedString: label.attributedText!)

    // Configure layoutManager and textStorage
    layoutManager.addTextContainer(textContainer)
    textStorage.addLayoutManager(layoutManager)

    // Configure textContainer
    textContainer.lineFragmentPadding = 0.0
    textContainer.lineBreakMode = label.lineBreakMode
    textContainer.maximumNumberOfLines = label.numberOfLines
    let labelSize = label.bounds.size
    textContainer.size = labelSize

    // Find the tapped character location and compare it to the specified range
    let locationOfTouchInLabel = self.location(in: label)
    let textBoundingBox = layoutManager.usedRect(for: textContainer)
    let textContainerOffset =
      CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
              y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
    let locationOfTouchInTextContainer =
      CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
              y: locationOfTouchInLabel.y - textContainerOffset.y)
    let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer,
                                                        in: textContainer,
                                                        fractionOfDistanceBetweenInsertionPoints: nil)
    return NSLocationInRange(indexOfCharacter, targetRange)
  }
}
