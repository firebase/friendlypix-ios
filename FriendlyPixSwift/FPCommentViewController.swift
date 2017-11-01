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
import Firebase

class FPCommentViewController: MDCCollectionViewController {
  var post: FPPost!
  var textField: UITextField!
  var comments: DatabaseReference!

  override func viewDidLoad() {
    super.viewDidLoad()

    comments = Database.database().reference(withPath: "comments/\(post.postID)")
      
    styler.cellStyle = .card

    textField = UITextField.init(frame: CGRect.init(x: 0, y: 0, width: 300, height: 50))
    textField.placeholder = "Add a comment"
    textField.addTarget(self, action: #selector(enterPressed), for: .editingDidEndOnExit)

    navigationController?.setToolbarHidden(false, animated: false)
    self.setToolbarItems([UIBarButtonItem.init(customView: textField), UIBarButtonItem.init(title: "Post", style: .plain, target: self, action: #selector(enterPressed))], animated: false)

    NotificationCenter.default.addObserver(self,
                                            selector: #selector(keyboardWillShow(notification:)),
                                            name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillHide(notification:)),
                                             name: NSNotification.Name.UIKeyboardWillHide, object: nil)
  }

  override func viewWillDisappear(_ animated: Bool) {
    self.navigationController?.setToolbarHidden(true, animated: false)
  }

  override func viewWillAppear(_ animated: Bool) {

  }

  @objc func enterPressed(){
    guard let currentUser = Auth.auth().currentUser else { return }
    guard let text = textField.text else { return }

    let data = ["timestamp": ServerValue.timestamp(), "author": ["uid": currentUser.uid, "full_name": currentUser.displayName ?? "", "profile_picture": currentUser.photoURL?.absoluteString], "text": text] as [String : Any]
    let comment = comments.childByAutoId()
    comment.setValue(data) { (error, reference) in
      if let error = error {
        print(error.localizedDescription)
        return
      }
      reference.observe(.value, with: { snapshot in
        self.post.comments.append(FPComment.init(snapshot: snapshot))
        self.collectionView?.insertItems(at: [IndexPath.init(item: self.post.comments.count-1, section: 0)])
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

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)

    if let textCell = cell as? MDCCollectionViewTextCell {
      let comment = post.comments[indexPath.item]
      textCell.textLabel?.numberOfLines = 0
      textCell.detailTextLabel?.text = "\(comment.from!.fullname): \(comment.text)"
      textCell.detailTextLabel?.numberOfLines = 0
      UIImage.circleImage(from: comment.from!.profilePictureURL, to: textCell.imageView!)
      textCell.imageView
    }
    
    return cell
  }
}
