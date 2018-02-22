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

class FPCommentViewController: MDCCollectionViewController, UITextFieldDelegate {
  var post: FPPost!
  var comments: [FPComment]!

  var commentsRef: DatabaseReference!
  var commentQuery: DatabaseQuery!
  let attributes = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14, weight: .medium)]
  var bottomConstraint: NSLayoutConstraint!
  var heightConstraint: NSLayoutConstraint!
  var inputBottomConstraint: NSLayoutConstraint!
  var sendBottomConstraint: NSLayoutConstraint!
  var editingIndex: IndexPath?
  let messageInputContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()

  var sizingCell: FPCardCollectionViewCell!

  var insets: UIEdgeInsets!

  var bottomAreaInset: CGFloat = 0

  let inputTextField: UITextField = {
    let textField = UITextField()
    textField.placeholder = "Add a comment"
    textField.addTarget(self, action: #selector(enterPressed), for: .editingDidEndOnExit)
    textField.addTarget(self, action: #selector(enterPressed), for: .touchUpInside)
    return textField
  }()

  let sendButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("Post", for: .normal)
    button.accessibilityHint = "Double-tap to post your comment"
    button.setTitleColor(UIColor.init(red: 0, green: 137/255, blue: 249/255, alpha: 1), for: .normal)
    button.titleLabel?.font = .boldSystemFont(ofSize: 16)
    button.addTarget(self, action: #selector(enterPressed), for: .touchUpInside)
    return button
  }()

  // Enable swipe-to-dismiss items.
  override func collectionViewAllowsSwipe(toDismissItem collectionView: UICollectionView) -> Bool {
    return true
  }

  // Override permissions at specific index paths.
  override func collectionView(_ collectionView: UICollectionView, canSwipeToDismissItemAt indexPath: IndexPath) -> Bool {
    return indexPath.section != 0 && comments[indexPath.item].from.userID == Auth.auth().currentUser?.uid
  }

  // Remove swiped index paths from our data.
  override func collectionView(_ collectionView: UICollectionView, willDeleteItemsAt indexPaths: [IndexPath]) {
    for indexPath in indexPaths {
      let commentID = comments[indexPath.item].commentID
      self.comments.remove(at: indexPath.item)
      commentsRef.child(commentID).removeValue()
    }
  }

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    comments = post.comments

    guard let collectionView = collectionView else {
      return
    }

    if #available(iOS 11.0, *) {
      bottomAreaInset = UIApplication.shared.keyWindow!.safeAreaInsets.bottom
    }

    commentsRef = Database.database().reference(withPath: "comments/\(post.postID)")
    styler.cellStyle = .card

    inputTextField.delegate = self

    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification),
                                           name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification),
                                           name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    insets = self.collectionView(collectionView,
                                 layout: collectionViewLayout,
                                 insetForSectionAt: 0)

    let col = collectionViewLayout as! UICollectionViewFlowLayout
    col.estimatedItemSize = CGSize.init(width: collectionView.bounds.width - insets.left - insets.right, height: 52)



    view.addSubview(messageInputContainerView)
    view.addConstraintsWithFormat(format: "H:|[v0]|", views: messageInputContainerView)

    heightConstraint = messageInputContainerView.heightAnchor.constraint(equalToConstant: 48 + bottomAreaInset)

    bottomConstraint = NSLayoutConstraint(item: messageInputContainerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
    view.addConstraint(bottomConstraint)
    view.addConstraint(heightConstraint)
    setupInputComponents()
  }

  private func setupInputComponents() {
    let topBorderView = UIView()
    topBorderView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
    messageInputContainerView.addSubview(inputTextField)
    messageInputContainerView.addSubview(sendButton)
    messageInputContainerView.addSubview(topBorderView)

    messageInputContainerView.addConstraintsWithFormat(format:  "H:|-8-[v0][v1(60)]|", views: inputTextField, sendButton)
    messageInputContainerView.addConstraintsWithFormat(format:  "H:|[v0]|", views: topBorderView)
    var bottomAreaInset: CGFloat = 0
    if #available(iOS 11.0, *) {
      bottomAreaInset = UIApplication.shared.keyWindow!.safeAreaInsets.bottom
    }

    inputTextField.topAnchor.constraint(equalTo: messageInputContainerView.topAnchor).isActive = true
    sendButton.topAnchor.constraint(equalTo: messageInputContainerView.topAnchor).isActive = true

    inputBottomConstraint = messageInputContainerView.bottomAnchor.constraint(equalTo: inputTextField.bottomAnchor, constant: bottomAreaInset)
    inputBottomConstraint.isActive = true

    sendBottomConstraint = messageInputContainerView.bottomAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: bottomAreaInset)
    sendBottomConstraint.isActive = true

    messageInputContainerView.addConstraintsWithFormat(format:  "V:|[v0(0.5)]", views: topBorderView)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    editingIndex = nil
    let lastCommentId = comments.last?.commentID
    commentQuery = commentsRef
    if let lastCommentId = lastCommentId {
      commentQuery = commentQuery.queryOrderedByKey().queryStarting(atValue: lastCommentId)
    } else {
      inputTextField.becomeFirstResponder()
    }
    commentQuery.observe(.childAdded, with: { dataSnaphot in
      if dataSnaphot.key != lastCommentId {
        self.comments.append(FPComment(snapshot: dataSnaphot))
        self.collectionView?.insertItems(at: [IndexPath(item: self.comments.count - 1, section: 1)])
      }
    })
    commentsRef.observe(.childRemoved) { dataSnaphot in
      if let index = self.comments.index(where: {$0.commentID == dataSnaphot.key}) {
        self.comments.remove(at: index)
        self.collectionView?.deleteItems(at: [IndexPath(item: index, section: 1)])
      }
    }
    commentsRef.observe(.childChanged) { dataSnaphot in
      if let value = dataSnaphot.value as? [String: Any],
        let index = self.comments.index(where: {$0.commentID == dataSnaphot.key}) {
        self.comments[index].text = value["text"] as! String
        self.collectionView?.reloadItems(at: [IndexPath(item: index, section: 1)])
        self.collectionViewLayout.invalidateLayout()
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.navigationController?.setToolbarHidden(true, animated: false)
    self.commentsRef.removeAllObservers()
    self.commentQuery.removeAllObservers()
  }

  @objc func enterPressed() {
    guard let currentUser = Auth.auth().currentUser else { return }
    guard let text = inputTextField.text else { return }

    let data = ["timestamp": ServerValue.timestamp(),
                "author": ["uid": currentUser.uid, "full_name": currentUser.displayName ?? "",
                           "profile_picture": currentUser.photoURL?.absoluteString], "text": text] as [String: Any]
    let comment = editingIndex == nil ? commentsRef.childByAutoId() : commentsRef.child(comments[(editingIndex?.item)!].commentID)

    comment.setValue(data) { error, reference in
      if let error = error {
        print(error.localizedDescription)
        return
      }
    }
    editingIndex = nil
    inputTextField.text = nil
    inputTextField.endEditing(true)
  }

  @objc func handleKeyboardNotification(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
      let isKeyboardShowing = notification.name == NSNotification.Name.UIKeyboardWillShow
      bottomConstraint?.constant = isKeyboardShowing ? -keyboardSize.height : 0
      heightConstraint?.constant = isKeyboardShowing ? 48 : 48 + bottomAreaInset
      inputBottomConstraint?.constant = isKeyboardShowing ? 0 : bottomAreaInset
      sendBottomConstraint?.constant = isKeyboardShowing ? 0 : bottomAreaInset
      if let animationDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? Double {
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
          self.view.layoutIfNeeded()
        }, completion: { completed in
          if isKeyboardShowing {
            if !self.comments.isEmpty{
              let indexPath = self.editingIndex ?? IndexPath(item: self.comments.count - 1, section: 1)
              self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
            }
          }
        })
      }
    }
  }

  @IBAction func didTapEdit(_ sender: UIButton) {
    let buttonPosition = sender.convert(CGPoint(), to: collectionView)
    if let indexPath = collectionView?.indexPathForItem(at: buttonPosition), indexPath.section == 1 {
      editingIndex = indexPath
      inputTextField.becomeFirstResponder()
      inputTextField.text = comments[indexPath.item].text
    }
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    }
    return comments.count
  }

  @objc func showProfile(sender: UITapGestureRecognizer) {
    if let index = sender.view?.tag {
      let sender = index == -1 ? post.author : comments[index].from
      feedViewController?.performSegue(withIdentifier: "account", sender: sender)
    }
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    editingIndex = nil
    inputTextField.text = nil
    inputTextField.endEditing(true)
  }

  @objc func handleTapOnComment(recognizer: UITapGestureRecognizer) {
    guard let label = recognizer.view as? UILabel else { return }
    let from = label.tag == -1 ? post.author : comments[label.tag].from
    if recognizer.didTapAttributedTextInLabel(label: label,
                                             inRange: NSRange(location: 0,
                                                              length: from.fullname.count)) {
      feedViewController?.performSegue(withIdentifier: "account", sender: from)
    }
  }

  override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
    let comment = comments[indexPath.item]
    let from = indexPath.section == 0 ? post.author : comment.from
    let label = UILabel()
    let text = NSMutableAttributedString(string: from.fullname , attributes: attributes)
    text.append(NSAttributedString(string: " " + (indexPath.section == 0 ? post.text : comment.text)))

    label.attributedText = text
    label.numberOfLines = 0
    label.contentMode = .left
    label.lineBreakMode = .byWordWrapping
    label.baselineAdjustment = .alignBaselines
    label.font = UIFont.systemFont(ofSize: 14)
    let size = label.sizeThatFits(CGSize(width: collectionView.bounds.width - insets.left - insets.right - 8 - 36 - 16 - 40, height: .greatestFiniteMagnitude))
    return size.height + 35.333333
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    if let cell = cell as? FPCommentCell {
      cell.label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                             action: #selector(handleTapOnComment(recognizer:))))
      cell.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showProfile(sender:))))

      cell.label.preferredMaxLayoutWidth = collectionView.bounds.width - insets.left - insets.right - 8 - 36 - 16 - 40
      if indexPath.section == 0 {
        cell.populateContent(from: post.author, text: post.text, date: post.postDate, index: -1, isDryRun: false)
      } else {
        let comment = comments[indexPath.item]
        cell.populateContent(from: comment.from, text: comment.text, date: comment.postDate, index: indexPath.item, isDryRun: false)
        cell.moreButton.isHidden = comment.from.userID != Auth.auth().currentUser?.uid
      }
    }
    return cell
  }
}

extension UIView {
  func addConstraintsWithFormat(format: String, views: UIView...) {
    var viewsDictionary = [String: UIView]()
    for (index, view) in views.enumerated() {
      let key = "v\(index)"
      view.translatesAutoresizingMaskIntoConstraints = false
      viewsDictionary[key] = view
    }

    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary))
  }
}
