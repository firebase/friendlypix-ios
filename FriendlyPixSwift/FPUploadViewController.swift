//
//  FPUploadViewController.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 11/6/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import UIKit
import MaterialComponents
import Firebase
import Photos

class FPUploadViewController: UIViewController, UITextFieldDelegate {
  @IBOutlet weak var imageView: UIImageView!
  var image: UIImage!
  var referenceURL: URL!
  var textFieldControllerFloating: MDCTextInputControllerDefault!
  @IBOutlet weak var textField: MDCTextField!
  @IBOutlet weak var button: MDCButton!
  let ref = Database.database().reference()
  let uid = Auth.auth().currentUser!.uid


  override func viewDidLoad() {
    imageView.image = image

    textField.delegate = self
    textFieldControllerFloating = MDCTextInputControllerDefault(textInput: textField)

    button.sizeToFit()
    button.setElevation(ShadowElevation.raisedButtonResting, for: .normal)
    button.setElevation(ShadowElevation.raisedButtonPressed, for: .highlighted)
  }


  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    uploadPressed(button)
    textField.resignFirstResponder()
    return true
  }

  @IBAction func uploadPressed(_ sender: Any) {
    let postRef = ref.child("posts").childByAutoId()
    let postId = postRef.key
    let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceURL], options: nil)
    let asset = assets.firstObject
    asset?.requestContentEditingInput(with: nil, completionHandler: { (contentEditingInput, info) in
      let imageFile = contentEditingInput?.fullSizeImageURL
      let filePath = "\(self.uid)/\(postId)/\(self.referenceURL.lastPathComponent)"
      let metadata = StorageMetadata()
      metadata.contentType = "image/jpeg"
      let storageRef = Storage.storage().reference()
      storageRef.child(filePath).putFile(from: imageFile!, metadata: metadata, completion: { (metadata, error) in
        if let error = error {
          print("Error uploading: \(error.localizedDescription)")
          return
        }
        let fileUrl = metadata?.downloadURLs?[0].absoluteString
        let storageUri = storageRef.child((metadata?.path!)!).description
        let trimmedComment = self.textField.text?.trimmingCharacters(in: CharacterSet.whitespaces)
        let data = ["url": fileUrl ?? "", "storage_uri": storageUri, "text": trimmedComment ?? "", "author": FPCurrentUser.shared.user.author(), "timestamp": ServerValue.timestamp] as [String : Any]
        postRef.setValue(data)
        postRef.root.updateChildValues(["people/\(self.uid)/posts/\(postId)": true, "feed/\(self.uid)/\(postId)": true])
        self.parent?.dismiss(animated: true, completion: nil)
      })
    })

  }
  

}
