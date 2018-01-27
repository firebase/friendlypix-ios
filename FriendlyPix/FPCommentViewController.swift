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
import MHPrettyDate


class FPCommentViewController: MDCCollectionViewController, UITextFieldDelegate {
  var post: FPPost!

  var comments: DatabaseReference!
  var commentQuery: DatabaseQuery!
  let attributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)]
  var bottomConstraint: NSLayoutConstraint!
  let messageInputContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()

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
    button.setTitleColor(UIColor.init(red: 0, green: 137/255, blue: 249/255, alpha: 1), for: .normal)
    button.titleLabel?.font = .boldSystemFont(ofSize: 16)
    return button
  }()


  func textFieldDidBeginEditing(_ textField: UITextField) {
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    comments = Database.database().reference(withPath: "comments/\(post.postID)")
    styler.cellStyle = .card

    inputTextField.delegate = self

    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification),
                                           name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification),
                                           name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
      flowLayout.estimatedItemSize = CGSize(width: 300, height: 50)
    }

    view.addSubview(messageInputContainerView)
    view.addConstraintsWithFormat(format: "H:|[v0]|", views: messageInputContainerView)
        if UIDevice().userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height == 2436 {
          // Accommodate insets for iPhone X.
          view.addConstraintsWithFormat(format: "V:[v0(68)]", views: messageInputContainerView)
        } else {
    view.addConstraintsWithFormat(format: "V:[v0(48)]", views: messageInputContainerView)
        }
    bottomConstraint = NSLayoutConstraint(item: messageInputContainerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
    view.addConstraint(bottomConstraint)
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
    if UIDevice().userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height == 2436 {
      // Accommodate insets for iPhone X.
      messageInputContainerView.addConstraintsWithFormat(format:  "V:|[v0]-20-|", views: inputTextField)
      messageInputContainerView.addConstraintsWithFormat(format:  "V:|[v0]-20-|", views: sendButton )
    } else {
      messageInputContainerView.addConstraintsWithFormat(format:  "V:|[v0]|", views: inputTextField)
      messageInputContainerView.addConstraintsWithFormat(format:  "V:|[v0]|", views: sendButton)
    }
    messageInputContainerView.addConstraintsWithFormat(format:  "V:|[v0(0.5)]", views: topBorderView)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    let lastCommentId = post.comments.last?.commentID
    commentQuery = comments
    if let lastCommentId = lastCommentId {
      commentQuery = commentQuery.queryOrderedByKey().queryStarting(atValue: lastCommentId)
    } else {
      inputTextField.becomeFirstResponder()
    }
    commentQuery.observe(.childAdded, with: { dataSnaphot in
      if dataSnaphot.key != lastCommentId {
        self.post.comments.append(FPComment(snapshot: dataSnaphot))
        self.collectionView?.insertItems(at: [IndexPath(item: self.post.comments.count - 1, section: 0)])
      }
    })
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.navigationController?.setToolbarHidden(true, animated: false)
    self.comments.removeAllObservers()
    self.commentQuery.removeAllObservers()
  }

  @objc func enterPressed() {
    guard let currentUser = Auth.auth().currentUser else { return }
    guard let text = inputTextField.text else { return }

    let data = ["timestamp": ServerValue.timestamp(),
                "author": ["uid": currentUser.uid, "full_name": currentUser.displayName ?? "",
                           "profile_picture": currentUser.photoURL?.absoluteString], "text": text] as [String: Any]
    let comment = comments.childByAutoId()
    comment.setValue(data) { error, reference in
      if let error = error {
        print(error.localizedDescription)
        return
      }
    }
    inputTextField.text = nil
    inputTextField.endEditing(true)
  }

  @objc func handleKeyboardNotification(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
      let isKeyboardShowing = notification.name == NSNotification.Name.UIKeyboardWillShow
      bottomConstraint?.constant = isKeyboardShowing ? -keyboardSize.height : 0
      if let animationDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? Double {
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
          self.view.layoutIfNeeded()
        }, completion: { completed in
          if isKeyboardShowing {
            let indexPath = IndexPath(item: self.post.comments.count - 1, section: 0)
            self.collectionView?.scrollToItem(at: indexPath, at: .bottom, animated: true)
          }
        })
      }
    }
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return post.comments.count
  }

  @objc func showProfile(sender: UITapGestureRecognizer) {
    if let index = sender.view?.tag {
      feedViewController?.performSegue(withIdentifier: "account", sender: post.comments[index].from)
    }
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    inputTextField.endEditing(true)
  }

  @objc func handleTapOnComment(recognizer: UITapGestureRecognizer) {
    if let label = recognizer.view as? UILabel, let from = post.comments[label.tag].from,
      recognizer.didTapAttributedTextInLabel(label: label,
                                             inRange: NSRange(location: 0,
                                                              length: from.fullname.count)) {
      feedViewController?.performSegue(withIdentifier: "account", sender: from)
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    if let cell = cell as? FPCommentCell {
      let comment = post.comments[indexPath.item]
      if let from = comment.from {
        cell.label.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                               action: #selector(handleTapOnComment(recognizer:))))
        cell.label.tag = indexPath.item

        let text = NSMutableAttributedString(string: from.fullname, attributes: attributes)
        text.append(NSAttributedString(string: " " + comment.text))
        cell.label.attributedText = text

        if let profilePictureURL = from.profilePictureURL {
          UIImage.circleImage(with: profilePictureURL, to: cell.imageView)
        }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showProfile(sender:)))
        cell.imageView.tag = indexPath.item
        cell.imageView.addGestureRecognizer(tapGestureRecognizer)
      }
      cell.dateLabel.text = MHPrettyDate.prettyDate(from: comment.postDate, with: MHPrettyDateShortRelativeTime)
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
