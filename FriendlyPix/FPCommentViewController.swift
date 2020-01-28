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
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, eitheimputVir express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Firebase
import MaterialComponents

class FPCommentViewController: UICollectionViewController, UITextViewDelegate {
  var post: FPPost!
  var comments: [FPComment]!
  lazy var appDelegate = UIApplication.shared.delegate as! AppDelegate
  lazy var currentUser = Auth.auth().currentUser!
  lazy var uid = currentUser.uid

  lazy var database = Database.database()
  lazy var commentsRef = database.reference(withPath: "comments/\(post.postID)")
  var commentQuery: DatabaseQuery!
  let attributes = [NSAttributedString.Key.font: UIFont.mdc_preferredFont(forMaterialTextStyle: .body2)]
  let attributes2 = [NSAttributedString.Key.font: UIFont.mdc_preferredFont(forMaterialTextStyle: .body1)]
  var bottomConstraint: NSLayoutConstraint!
  var heightConstraint: NSLayoutConstraint!
  var inputBottomConstraint: NSLayoutConstraint!
  var sendBottomConstraint: NSLayoutConstraint!
  var editingIndex: IndexPath!
  let messageInputContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()
  var requestWorkItem: DispatchWorkItem?
  var isEditingComment = false
  var isKeyboardShown = false

  let commentDeleteText = MDCSnackbarMessage.init(text: "Comment deleted")

  var insets: UIEdgeInsets!

  var bottomAreaInset: CGFloat = 0

  let inputTextView: UITextView = {
    let textView = UITextView(placeholder: "Add a comment")

    textView.font = UIFont.preferredFont(forTextStyle: .footnote)
    textView.isScrollEnabled = false
    return textView
  }()

  var updatedLabel: UILabel!

  let sendButton: UIButton = {
    let button = UIButton(type: .custom)
    button.setImage(#imageLiteral(resourceName: "ic_send"), for: .normal)
    button.tintColor = UIColor.init(red: 0, green: 137/255, blue: 249/255, alpha: 1)
    button.accessibilityLabel = "Send comment"
    button.isEnabled = false
    button.addTarget(self, action: #selector(enterPressed), for: .touchUpInside)
    return button
  }()

  func deleteComment(_ indexPath: IndexPath) {
    requestWorkItem?.perform()
    let commentID = comments[indexPath.item].commentID
    let comment = comments.remove(at: indexPath.item)
    collectionView?.deleteItems(at: [indexPath])

    requestWorkItem = DispatchWorkItem { [weak self] in
      self?.commentsRef.child(commentID).removeValue()
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4),
                                  execute: requestWorkItem!)

    let action = MDCSnackbarMessageAction()
    action.handler = {
      self.requestWorkItem?.cancel()
      let index = min(indexPath.item, self.comments.count)
      self.comments.insert(comment, at: index)
      self.collectionView?.insertItems(at: [IndexPath(item: index, section: 1)])
    }
    action.title = "Undo"
    commentDeleteText.action = action
    MDCSnackbarManager.show(commentDeleteText)
  }

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    isEditingComment = false
    sendButton.isEnabled = false
    heightConstraint.constant = 48 + bottomAreaInset
  }

  func textViewDidChange(_ textView: UITextView) {
    sendButton.isEnabled = !textView.text.isEmpty
    let size = CGSize(width: view.frame.width - 60, height: .infinity)
    let estimatedSize = textView.sizeThatFits(size)
    heightConstraint.constant = estimatedSize.height + 14 + (bottomConstraint.constant == 0 ? bottomAreaInset : 0)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    comments = post.comments

    guard let collectionView = collectionView else {
      return
    }

    collectionView.register(MDCSelfSizingStereoCell.self, forCellWithReuseIdentifier: "cell")

    if #available(iOS 11.0, *) {
      bottomAreaInset = UIApplication.shared.keyWindow!.safeAreaInsets.bottom
    }

    inputTextView.delegate = self
    inputTextView.isEditable = !currentUser.isAnonymous

    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification),
                                           name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification),
                                           name: UIResponder.keyboardWillHideNotification, object: nil)

    let col = collectionViewLayout as! UICollectionViewFlowLayout
    col.estimatedItemSize = CGSize.init(width: collectionView.bounds.width, height: 52)

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
    messageInputContainerView.addSubview(inputTextView)
    messageInputContainerView.addSubview(sendButton)
    messageInputContainerView.addSubview(topBorderView)

    messageInputContainerView.addConstraintsWithFormat(format:  "H:|-8-[v0][v1(52)]|", views: inputTextView, sendButton)
    messageInputContainerView.addConstraintsWithFormat(format:  "H:|[v0]|", views: topBorderView)
    var bottomAreaInset: CGFloat = 0
    if #available(iOS 11.0, *) {
      bottomAreaInset = UIApplication.shared.keyWindow!.safeAreaInsets.bottom
    }

    inputTextView.topAnchor.constraint(equalTo: messageInputContainerView.topAnchor, constant: 6).isActive = true

    inputBottomConstraint = messageInputContainerView.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor, constant: bottomAreaInset)
    inputBottomConstraint.isActive = true

    sendBottomConstraint = messageInputContainerView.bottomAnchor.constraint(equalTo: sendButton.bottomAnchor, constant: bottomAreaInset + 12)
    sendBottomConstraint.isActive = true

    messageInputContainerView.addConstraintsWithFormat(format:  "V:|[v0(0.5)]", views: topBorderView)
  }


  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged,
                                    argument: collectionView)
    MDCSnackbarManager.setBottomOffset(0)
    isEditingComment = false
    let lastCommentId = comments.last?.commentID
    commentQuery = commentsRef
    if let lastCommentId = lastCommentId {
      commentQuery = commentQuery.queryOrderedByKey().queryStarting(atValue: lastCommentId)
    } else {
      inputTextView.becomeFirstResponder()
    }
    commentQuery.observe(.childAdded, with: { dataSnaphot in
      if dataSnaphot.key != lastCommentId && !self.appDelegate.isBlocked(dataSnaphot){
        self.comments.append(FPComment(snapshot: dataSnaphot))
        let index = IndexPath(item: self.comments.count - 1, section: 1)
        self.collectionView?.insertItems(at: [index])
        self.updatedLabel = (self.collectionView?.cellForItem(at: index) as! MDCSelfSizingStereoCell).titleLabel
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged,
                                        argument: self.updatedLabel)
      }
    })
    commentsRef.observe(.childRemoved) { dataSnaphot in
      if let index = self.comments.firstIndex(where: {$0.commentID == dataSnaphot.key}) {
        self.comments.remove(at: index)
        self.collectionView?.deleteItems(at: [IndexPath(item: index, section: 1)])
      }
    }
    commentsRef.observe(.childChanged) { dataSnaphot in
      if let value = dataSnaphot.value as? [String: Any],
        let index = self.comments.firstIndex(where: {$0.commentID == dataSnaphot.key}) {
        self.comments[index].text = value["text"] as! String
        let indexPath = IndexPath(item: index, section: 1)
        self.collectionView?.reloadItems(at: [indexPath])
        self.collectionViewLayout.invalidateLayout()
        self.updatedLabel = (self.collectionView?.cellForItem(at: indexPath) as! MDCSelfSizingStereoCell).titleLabel
        UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged,
                                        argument: self.updatedLabel)
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    inputTextView.endEditing(true)
    super.viewWillDisappear(animated)
    self.navigationController?.setToolbarHidden(true, animated: false)
    self.commentsRef.removeAllObservers()
    self.commentQuery.removeAllObservers()
    MDCSnackbarManager.dismissAndCallCompletionBlocks(withCategory: nil)
    requestWorkItem?.perform()
  }

  @objc func enterPressed() {
    guard let currentUser = Auth.auth().currentUser else { return }
    guard let text = inputTextView.text else { return }

    if !text.isEmpty {
      let data = ["timestamp": ServerValue.timestamp(),
                  "author": ["uid": currentUser.uid,
                             "full_name": currentUser.displayName ?? "",
                             "profile_picture": currentUser.photoURL?.absoluteString],
                  "text": text] as [String: Any]
      let comment = isEditingComment ? commentsRef.child(comments[editingIndex.item].commentID) : commentsRef.childByAutoId()

      comment.setValue(data) { error, reference in
        if let error = error {
          print(error.localizedDescription)
          return
        }
      }
      inputTextView.text = nil
      inputTextView.textViewDidChange(inputTextView)
    }
    inputTextView.endEditing(true)
  }

  @objc func handleKeyboardNotification(notification: NSNotification) {
    let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
    if self.isKeyboardShown == isKeyboardShowing {
      return
    }
    self.isKeyboardShown = isKeyboardShowing
    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
      bottomConstraint?.constant = isKeyboardShowing ? -keyboardSize.height : 0
      let inset = isKeyboardShowing ? -bottomAreaInset : bottomAreaInset
      heightConstraint?.constant += inset
      inputBottomConstraint?.constant = isKeyboardShowing ? 0 : bottomAreaInset
      sendBottomConstraint?.constant = isKeyboardShowing ? 12 : (12 + bottomAreaInset)
      if let animationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
          self.view.layoutIfNeeded()
        }, completion: { completed in
          if isKeyboardShowing {
            if !self.comments.isEmpty{
              let indexPath = self.isEditingComment ? self.editingIndex : IndexPath(item: self.comments.count - 1, section: 1)
              self.collectionView?.scrollToItem(at: indexPath!, at: .bottom, animated: true)
            }
          } else {
            MDCSnackbarManager.setBottomOffset(0)
            if let updatedLabel = self.updatedLabel {
              UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged,
                                              argument: updatedLabel)
            }
          }
        })
      }
    }
  }

  @IBAction func didTapEdit(_ sender: UIButton) {
    let buttonPosition = sender.convert(CGPoint(), to: collectionView)
    if let indexPath = collectionView?.indexPathForItem(at: buttonPosition), indexPath.section == 1 {
      let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
      let comment = comments[indexPath.item]
      if comment.from.uid == uid {
        alert.addAction(UIAlertAction(title: "Edit", style: .default , handler:{ _ in
          self.editComment(indexPath)
        }))

        alert.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ _ in
          self.deleteComment(indexPath)
        }))
      } else {
        alert.addAction(UIAlertAction(title: "Report", style: .destructive , handler:{ _ in
          let alertController = MDCAlertController.init(title: "Report Comment?", message: nil)
          let cancelAction = MDCAlertAction(title: "Cancel", handler: nil)
          let reportAction = MDCAlertAction(title: "Report") { _ in
            self.database.reference(withPath: "commentFlags/\(self.post.postID)/\(comment.commentID)/\(self.uid)").setValue(true)
          }
          alertController.addAction(reportAction)
          alertController.addAction(cancelAction)
          self.present(alertController, animated: true, completion: nil)
        }))
      }
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel , handler: nil))
      alert.popoverPresentationController?.sourceRect = sender.bounds
      alert.popoverPresentationController?.sourceView = sender
      self.present(alert, animated: true, completion: nil)
    }
  }

  func editComment(_ indexPath: IndexPath) {
    isEditingComment = true
    editingIndex = indexPath
    inputTextView.becomeFirstResponder()
    inputTextView.text = comments[indexPath.item].text
    inputTextView.textViewDidChange(inputTextView)
    textViewDidChange(inputTextView)
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    }
    return comments.count
  }

  func textViewDidBeginEditing(_ textView: UITextView) {
    textViewDidChange(textView)
  }

  @objc func showProfile(sender: UITapGestureRecognizer) {
    if let index = sender.view?.tag {
      let sender = index == -1 ? post.author : comments[index].from
      feedViewController.performSegue(withIdentifier: "account", sender: sender)
    }
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    inputTextView.endEditing(true)
  }

  @objc func handleTapOnComment(recognizer: UITapGestureRecognizer) {
    guard let label = recognizer.view as? UILabel else { return }
    let from = label.tag == -1 ? post.author : comments[label.tag].from
    if recognizer.didTapAttributedTextInLabel(label: label,
                                             inRange: NSRange(location: 0,
                                                              length: from.fullname.count)) {
      feedViewController.performSegue(withIdentifier: "account", sender: from)
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    if let cell = cell as? MDCSelfSizingStereoCell {
      cell.titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                             action: #selector(handleTapOnComment(recognizer:))))
      cell.titleLabel.isUserInteractionEnabled = true
      cell.leadingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showProfile(sender:))))
      cell.leadingImageView.isUserInteractionEnabled = true

      if indexPath.section == 0 {
        cell.populateContent(from: post.author, text: post.text, date: post.postDate, index: -1)
        cell.trailingImageView.isHidden = true
      } else {
        let comment = comments[indexPath.item]
        cell.populateContent(from: comment.from, text: comment.text, date: comment.postDate, index: indexPath.item)
        cell.trailingImageView.image = #imageLiteral(resourceName: "ic_more_vert_white")
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

    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
  }
}
