//
//  FPTabBarController.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 10/5/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialAppBar
import MaterialComponents.MaterialButtons

protocol FPTabBarControllerDelegate {
  func fpTabBarControllerDelegate_CenterButtonTapped(tabBarController:FPTabBarController)
}

class FPTabBarController: UITabBarController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  var centerButton: MDCFloatingButton!
  var fpTabBarControllerDelegate:FPTabBarControllerDelegate?
  var alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

  override func viewDidLoad() {
    let button = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 36, height: 36))
    button.addTarget(self, action: #selector(clickUser), for: .touchUpInside)
    UIImage.circleButton(from: (FPCurrentUser.shared.user.profilePictureURL), to: button)

    navigationItem.rightBarButtonItems?.insert(UIBarButtonItem(customView: button), at: 0)

    let titleLabel = UILabel()
    titleLabel.text = "Friendly Pix"
    titleLabel.textColor = UIColor.white
    titleLabel.font = UIFont.init(name: "Amaranth", size: 24)
    titleLabel.sizeToFit()
    navigationItem.leftBarButtonItems?.append(UIBarButtonItem(customView: titleLabel))

    centerButton = MDCFloatingButton.init(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
    var centerButtonFrame = centerButton.frame
    centerButtonFrame.origin.y = view.bounds.height - centerButtonFrame.height
    centerButtonFrame.origin.x = view.bounds.width/2 - centerButtonFrame.size.width/2
    centerButton.frame = centerButtonFrame
    centerButton.backgroundColor = UIColor(red:1.00, green:0.79, blue:0.16, alpha:1.0)

    view.addSubview(centerButton)

    centerButton.setImage(#imageLiteral(resourceName: "ic_photo_camera"), for: .normal)
    centerButton.setImage(#imageLiteral(resourceName: "ic_photo_camera_white"), for: .highlighted)
    centerButton.addTarget(self, action: #selector(centerButtonAction(sender:)), for: .touchUpInside)

    view.layoutIfNeeded()

    let button0 = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alert.addAction(button0)

    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      let button1 = UIAlertAction(title: "Take photo", style: .default) { _ in
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .camera
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: nil)
      }
      alert.addAction(button1)
    }
    if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) || UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
      let button2 = UIAlertAction(title: "Choose Existing", style: .default) { _ in
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = UIImagePickerController.isSourceTypeAvailable(.photoLibrary) ? .photoLibrary : .savedPhotosAlbum
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: { })
      }
      alert.addAction(button2)
    }
  }

  @objc private func centerButtonAction(sender: UIButton) {
    present(alert, animated: true, completion: nil)
  }

  override func viewDidLayoutSubviews(){
    super.viewDidLayoutSubviews()

    view.bringSubview(toFront: self.centerButton)
  }

  @objc func clickUser() {
    let x = self.viewControllers?[0] as! FPFeedViewController
    x.clickUser()
  }

  // MARK: - UIImagePickerDelegate
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    dismiss(animated: false, completion: nil)
    performSegue(withIdentifier: "upload", sender: info)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if (segue.identifier == "upload") {
      let viewController = segue.destination as? FPUploadViewController
      if let sender = sender as? [String:Any] {
        if let image = sender[UIImagePickerControllerEditedImage] as? UIImage {
          viewController?.image = image
        } else if let image = sender[UIImagePickerControllerOriginalImage] as? UIImage {
          viewController?.image = image
        }
        viewController?.referenceURL = sender[UIImagePickerControllerReferenceURL] as? URL
      }
    }
  }

//  @IBAction func didTapSignOut(_ sender: Any) {
//    var signOutError: Error?
//    let status: Bool = FIRAuth().signOut(signOutError)
//    if !status {
//      print("Error signing out: \(signOutError)")
//      return
//    }
//    parent?.dismiss(animated: true) { _ in }
//  }
}
