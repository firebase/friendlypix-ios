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

class FPCommentViewController: MDCCollectionViewController {
  var post: FPPost!
  var textField: UITextField!
  var comments: DatabaseReference!
  let attributes: [String: UIFont] = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14)]

  override func viewDidLoad() {
    super.viewDidLoad()

    comments = Database.database().reference(withPath: "comments/\(post.postID)")
    styler.cellStyle = .card

    textField = UITextField(frame: CGRect(x: 0, y: 0, width: 300, height: 50))
    textField.placeholder = "Add a comment"
    textField.addTarget(self, action: #selector(enterPressed), for: .editingDidEndOnExit)

    navigationController?.setToolbarHidden(false, animated: false)
    self.setToolbarItems([UIBarButtonItem(customView: textField),
                          UIBarButtonItem(title: "Post", style: .plain, target: self,
                                          action: #selector(enterPressed))], animated: false)

    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)),
                                           name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)),
                                           name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    if let flowLayout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
      flowLayout.estimatedItemSize = CGSize(width: 300, height: 50)
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.navigationController?.setToolbarHidden(true, animated: false)
  }

  @objc func enterPressed() {
    guard let currentUser = Auth.auth().currentUser else { return }
    guard let text = textField.text else { return }

    let data = ["timestamp": ServerValue.timestamp(),
                "author": ["uid": currentUser.uid, "full_name": currentUser.displayName ?? "",
                           "profile_picture": currentUser.photoURL?.absoluteString], "text": text] as [String: Any]
    let comment = comments.childByAutoId()
    comment.setValue(data) { error, reference in
      if let error = error {
        print(error.localizedDescription)
        return
      }
      reference.observe(.value, with: { snapshot in
       // if let comment =
        self.post.comments.append(FPComment(snapshot: snapshot))
        self.collectionView?.insertItems(at: [IndexPath(item: self.post.comments.count - 1, section: 0)])
      })
    }
    textField.text = nil
    textField.resignFirstResponder()
  }

  func keyboardWillShow(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
      if let animationDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? Double {

      UIView.animate(withDuration: animationDuration) { () -> Void in
              self.navigationController?.toolbar.frame.origin.y -= keyboardSize.height
      }
      }
    }
  }
  func keyboardWillHide(notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
      if let animationDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as? Double {
        UIView.animate(withDuration: animationDuration) { () -> Void in
          self.navigationController?.toolbar.frame.origin.y += keyboardSize.height
        }
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

  @objc func handleTapOnComment(recognizer: UITapGestureRecognizer) {
    if let label = recognizer.view as? UILabel, let from = post.comments[label.tag].from,
      recognizer.didTapAttributedTextInLabel(label: label,
                                             inRange: NSRange(location: 0,
                                                              length: from.fullname.characters.count)) {
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
