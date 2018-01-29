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
  let ref = Database.database().reference()
  let uid = Auth.auth().currentUser!.uid

  override func viewDidLoad() {
    super.viewDidLoad()
    imageView.image = image

    textField.delegate = self
    textFieldControllerFloating = MDCTextInputControllerUnderline(textInput: textField)

    button.sizeToFit()
    button.setElevation(ShadowElevation.raisedButtonResting, for: .normal)
    button.setElevation(ShadowElevation.raisedButtonPressed, for: .highlighted)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    uploadPressed(button)
    return true
  }

  @IBAction func uploadPressed(_ sender: Any) {
    button.isEnabled = false
    textField.endEditing(true)
    let postRef = ref.child("posts").childByAutoId()
    let postId = postRef.key
    guard let resizedImageData = UIImageJPEGRepresentation(image, 0.9) else { return }
    guard let thumbnailImageData = image.resizeImage(640, with: 0.7) else { return }
    let fullFilePath = "\(self.uid)/full/\(postId)/jpeg"
    let thumbFilePath = "\(self.uid)/thumb/\(postId)/jpeg"
    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"
    let storageRef = Storage.storage().reference()
    let message = MDCSnackbarMessage()
    storageRef.child(fullFilePath).putData(resizedImageData, metadata: metadata) { fullmetadata, error in
      if let error = error {
        message.text = "Error uploading image"
        MDCSnackbarManager.show(message)
        self.button.isEnabled = true
        print("Error uploading image: \(error.localizedDescription)")
        return
      }
      storageRef.child(thumbFilePath).putData(thumbnailImageData, metadata: metadata) { thumbmetadata, error in
        if let error = error {
          message.text = "Error uploading thumbnail"
          MDCSnackbarManager.show(message)
          self.button.isEnabled = true
          print("Error uploading thumbnail: \(error.localizedDescription)")
          return
        }
        let fullUrl = fullmetadata?.downloadURLs?[0].absoluteString
        let fullstorageUri = storageRef.child((fullmetadata?.path!)!).description
        let thumbUrl = thumbmetadata?.downloadURLs?[0].absoluteString
        let thumbstorageUri = storageRef.child((thumbmetadata?.path!)!).description
        let trimmedComment = self.textField.text?.trimmingCharacters(in: CharacterSet.whitespaces)
        let data = ["full_url": fullUrl ?? "", "full_storage_uri": fullstorageUri,
                    "thumb_url": thumbUrl ?? "", "thumb_storage_uri": thumbstorageUri, "text": trimmedComment ?? "",
                  "author": FPUser.currentUser().author(), "timestamp": ServerValue.timestamp()] as [String: Any]
        postRef.setValue(data)
        postRef.root.updateChildValues(["people/\(self.uid)/posts/\(postId)": true, "feed/\(self.uid)/\(postId)": true])
        self.navigationController?.popViewController(animated: true)
      }
    }
  }
}
