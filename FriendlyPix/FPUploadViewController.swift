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

class FPUploadViewController: UIViewController, UITextFieldDelegate {
  @IBOutlet weak private var imageView: UIImageView!
  var image: UIImage!
  var textFieldControllerFloating: MDCTextInputControllerUnderline!
  @IBOutlet weak private var textField: MDCTextField!
  @IBOutlet weak private var button: MDCButton!
  lazy var database = Database.database()
  lazy var storage = Storage.storage()
  
  let uid = Auth.auth().currentUser!.uid
  var fullURL = ""
  var thumbURL = ""
  var spinner: UIView?

  override func viewDidLoad() {
    super.viewDidLoad()
    imageView.image = image

    textField.delegate = self
    textFieldControllerFloating = MDCTextInputControllerUnderline(textInput: textField)

    button.sizeToFit()
    button.setElevation(ShadowElevation.raisedButtonResting, for: .normal)
    button.setElevation(ShadowElevation.raisedButtonPressed, for: .highlighted)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if let spinner = spinner {
      removeSpinner(spinner)
    }
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    uploadPressed(button)
    return true
  }

  @IBAction func uploadPressed(_ sender: Any) {
    spinner = displaySpinner()
    button.isEnabled = false
    textField.endEditing(true)
    let postRef = database.reference(withPath: "posts").childByAutoId()
    let postId = postRef.key
    guard let resizedImageData = image.resizeImage(1280, with: 0.9) else { return }
    guard let thumbnailImageData = image.resizeImage(640, with: 0.7) else { return }
    let fullRef = storage.reference(withPath: "\(self.uid)/full/\(postId)/jpeg")
    let thumbRef = storage.reference(withPath: "\(self.uid)/thumb/\(postId)/jpeg")
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"

    let message = MDCSnackbarMessage()
    let myGroup = DispatchGroup()
    myGroup.enter()
    fullRef.putData(resizedImageData, metadata: metadata) { fullmetadata, error in
      if let error = error {
        message.text = "Error uploading image"
        MDCSnackbarManager.show(message)
        self.button.isEnabled = true
        print("Error uploading image: \(error.localizedDescription)")
        return
      }

      fullRef.downloadURL(completion: { (url, error) in
        if let error = error {
          print(error.localizedDescription)
          return
        }
        if let url = url?.absoluteString {
          self.fullURL = url
        }
        myGroup.leave()
      })
    }
    myGroup.enter()
    thumbRef.putData(thumbnailImageData, metadata: metadata) { thumbmetadata, error in
      if let error = error {
        message.text = "Error uploading thumbnail"
        MDCSnackbarManager.show(message)
        self.button.isEnabled = true
        print("Error uploading thumbnail: \(error.localizedDescription)")
        return
      }
      thumbRef.downloadURL(completion: { (url, error) in
        if let error = error {
          print(error.localizedDescription)
          return
        }
        if let url = url?.absoluteString {
          self.thumbURL = url
        }
        myGroup.leave()
      })
    }
    myGroup.notify(queue: .main) {
      if let spinner = self.spinner {
        self.removeSpinner(spinner)        
      }

      let trimmedComment = self.textField.text?.trimmingCharacters(in: CharacterSet.whitespaces)
      let data = ["full_url": self.fullURL, "full_storage_uri": fullRef.fullPath,
                  "thumb_url": self.thumbURL, "thumb_storage_uri": thumbRef.fullPath,
                  "text": trimmedComment ?? "", "client": "ios",
                  "author": FPUser.currentUser().author(), "timestamp": ServerValue.timestamp()] as [String: Any]
      postRef.setValue(data)
      postRef.root.updateChildValues(["people/\(self.uid)/posts/\(postId)": true, "feed/\(self.uid)/\(postId)": true])
      self.navigationController?.popViewController(animated: true)
    }
  }
}
