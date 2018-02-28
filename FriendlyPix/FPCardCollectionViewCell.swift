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
import SDWebImage

protocol FPCardCollectionViewCellDelegate: class {
  func showProfile(_ author: FPUser)
  func showLightbox(_ index: Int)
  func viewComments(_ post: FPPost)
  func toogleLike(_ post: FPPost, button: UIButton, label: UILabel)
  func deletePost(_ post: FPPost, completion: (() -> Swift.Void)? )
}

class FPCardCollectionViewCell: MDCCollectionViewCell {
  @IBOutlet weak private var authorImageView: UIImageView!
  @IBOutlet weak private var authorLabel: UILabel!
  @IBOutlet weak private var dateLabel: UILabel!
  @IBOutlet weak private var postImageView: UIImageView!
  @IBOutlet weak private var titleLabel: UILabel!
  @IBOutlet weak private var likesLabel: UILabel!
  @IBOutlet weak private var likeButton: UIButton!
  @IBOutlet weak private var deleteButton: UIButton!

  @IBOutlet weak private var comment1Label: UILabel!
  @IBOutlet weak private var comment2Label: UILabel!
  @IBOutlet weak private var comment3Label: UILabel!
  @IBOutlet weak private var viewAllCommentsLabel: UIButton!
  var commentLabels: [UILabel]?
  let attributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .medium)]

  var post: FPPost!
  weak var delegate: FPCardCollectionViewCellDelegate?
  var labelConstraints: [NSLayoutConstraint]!
  public var imageConstraint: NSLayoutConstraint?

  override func awakeFromNib() {
    super.awakeFromNib()

    authorImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))
    authorLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileTapped)))
    postImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageTapped)))
    authorImageView.isAccessibilityElement = true
    authorImageView.accessibilityHint = "Double-tap to open profile."
    
    commentLabels = [comment1Label, comment2Label, comment3Label]

    comment1Label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                              action: #selector(handleTapOnComment(recognizer:))))
    comment2Label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                              action: #selector(handleTapOnComment(recognizer:))))
    comment3Label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                              action: #selector(handleTapOnComment(recognizer:))))
    print(self.bounds.width)
    titleLabel.preferredMaxLayoutWidth = self.bounds.width - 24
    comment1Label.preferredMaxLayoutWidth = titleLabel.preferredMaxLayoutWidth
    comment2Label.preferredMaxLayoutWidth = titleLabel.preferredMaxLayoutWidth
    comment3Label.preferredMaxLayoutWidth = titleLabel.preferredMaxLayoutWidth
  }

  func populateContent(post: FPPost, index: Int, isDryRun: Bool) {
    self.post = post
    let postAuthor = post.author
    if !isDryRun, let profilePictureURL = postAuthor.profilePictureURL {
      UIImage.circleImage(with: profilePictureURL, to: authorImageView)
      authorImageView.accessibilityLabel = postAuthor.fullname
    }
    authorLabel?.text = postAuthor.fullname
    dateLabel?.text = post.postDate.timeAgo()
    postImageView.tag = index
    if !isDryRun {
      postImageView?.sd_setImage(with: post.thumbURL, completed: nil)
      postImageView.accessibilityLabel = "Photo by \(postAuthor.fullname)"
    }

    let title = NSMutableAttributedString(string: postAuthor.fullname, attributes: attributes)
    title.append(NSAttributedString(string: " " + post.text))
    title.addAttribute(.paragraphStyle, value: FPCommentCell.paragraphStyle, range: NSMakeRange(0, title.length))
    titleLabel?.attributedText = title
    titleLabel?.accessibilityLabel = "\(post.text), posted by \(postAuthor.fullname)"

    titleLabel?.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                            action: #selector(handleTapOnProfileLabel(recognizer:))))
    likesLabel?.text = post.likeCount == 1 ? "1 like" : "\(post.likeCount) likes"
    if post.isLiked {
      likeButton.setImage(#imageLiteral(resourceName: "ic_favorite"), for: .normal)
      likeButton.accessibilityLabel = "you liked this post"
      likeButton.accessibilityHint = "double-tap to unlike"
    } else {
      likeButton.setImage(#imageLiteral(resourceName: "ic_favorite_border"), for: .normal)
      likeButton.accessibilityLabel = "you haven't liked this post"
      likeButton.accessibilityHint = "double-tap to like"
    }

    deleteButton.isHidden = !post.mine

    if labelConstraints != nil {
      NSLayoutConstraint.deactivate(labelConstraints)
      labelConstraints = nil
    }

    let betweenConstant: CGFloat = 0
    let bottomConstant: CGFloat = -8
    let commentCount = post.comments.count
    switch commentCount {
    case 0:
      labelConstraints = [titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                             constant: bottomConstant)]
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
    case 3:
      labelConstraints = [comment1Label.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                             constant: betweenConstant),
                          comment2Label.topAnchor.constraint(equalTo: comment1Label.bottomAnchor,
                                                             constant: betweenConstant),
                          comment3Label.topAnchor.constraint(equalTo: comment2Label.bottomAnchor,
                                                             constant: betweenConstant),
                          comment3Label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor,
                                                                constant: bottomConstant)]
      viewAllCommentsLabel.isHidden = true
      attributeComment(index: 0)
      attributeComment(index: 1)
      attributeComment(index: 2)
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
      commentLabel.accessibilityLabel = "\(comment.from.fullname) said, \(comment.text)"
      let text = NSMutableAttributedString(string: comment.from.fullname, attributes: attributes)
      text.append(NSAttributedString(string: " " + comment.text))
      text.addAttribute(.paragraphStyle, value: FPCommentCell.paragraphStyle, range: NSMakeRange(0, text.length))
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

  @IBAction func tappedDelete() {
    delegate?.deletePost(post, completion: nil)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    NSLayoutConstraint.deactivate(labelConstraints)
    labelConstraints = nil
  }

  @objc func profileTapped() {
    delegate?.showProfile(post.author)
  }

  @objc func imageTapped() {
    delegate?.showLightbox(postImageView.tag)
  }

  @objc func handleTapOnProfileLabel(recognizer: UITapGestureRecognizer) {
    if recognizer.didTapAttributedTextInLabel(label: titleLabel,
                                              inRange: NSRange(location: 0,
                                                               length: post.author.fullname.count)) {
      profileTapped()
    }
  }

  @objc func handleTapOnComment(recognizer: UITapGestureRecognizer) {
    if let index = recognizer.view?.tag {
      let from = post.comments[index].from
      if recognizer.didTapAttributedTextInLabel(label: commentLabels![index],
                                             inRange: NSRange(location: 0,
                                                              length: from.fullname.count)) {
        delegate?.showProfile(from)
      }
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
