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
import FirebaseMLVision
import MaterialComponents

class FPUploadViewController: UIViewController, UITextViewDelegate {
  @IBOutlet weak private var imageView: UIImageView!
  private var bottomConstraint: NSLayoutConstraint!
  private var heightConstraint: NSLayoutConstraint!
  private var inputBottomConstraint: NSLayoutConstraint!
  private var sendBottomConstraint: NSLayoutConstraint!
  private var isKeyboardShown = false
  private let messageInputContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = .white
    return view
  }()

  var bottomAreaInset: CGFloat = 0

  let inputTextView: UITextView = {
    let textView = UITextView(placeholder: "Write a caption...")
    textView.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.callout)
    textView.isScrollEnabled = false
    textView.returnKeyType = .done
    return textView
  }()

  let smartTagsView: UIStackView = {
    let view = UIStackView()
    view.distribution = .equalSpacing
    return view
  }()

  let sendButton: MDCFloatingButton = {
    let button = MDCFloatingButton(shape: .mini)
    button.setImage(#imageLiteral(resourceName: "ic_send"), for: .normal)
    button.tintColor = .blue
    button.backgroundColor = .white
    button.accessibilityLabel = "Upload"
    button.isEnabled = false
    button.addTarget(self, action: #selector(uploadPressed(_:)), for: .touchUpInside)
    return button
  }()

  var image: UIImage!
  var vision: Vision!
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
    detectLabelsInImage()

    if #available(iOS 11.0, *) {
      bottomAreaInset = UIApplication.shared.keyWindow!.safeAreaInsets.bottom
    }
    inputTextView.delegate = self

    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification),
                                           name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification),
                                           name: UIResponder.keyboardWillHideNotification, object: nil)
    view.addSubview(messageInputContainerView)

    view.addConstraintsWithFormat(format: "H:|[v0]|", views: messageInputContainerView)

    heightConstraint = messageInputContainerView.heightAnchor.constraint(equalToConstant: 88 + bottomAreaInset)

    bottomConstraint = NSLayoutConstraint(item: messageInputContainerView, attribute: .bottom, relatedBy: .equal,
                                          toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
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
    messageInputContainerView.addSubview(smartTagsView)

    messageInputContainerView.addConstraintsWithFormat(format: "H:|-8-[v0][v1(40)]-16-|",
                                                       views: inputTextView, sendButton)
    messageInputContainerView.addConstraintsWithFormat(format: "H:|[v0]|", views: topBorderView)
    messageInputContainerView.addConstraintsWithFormat(format: "H:|-16-[v0]-16-|", views: smartTagsView)

    smartTagsView.topAnchor.constraint(equalTo: messageInputContainerView.topAnchor, constant: 6).isActive = true
    smartTagsView.bottomAnchor.constraint(equalTo: inputTextView.topAnchor, constant: -6).isActive = true

    inputBottomConstraint = messageInputContainerView.bottomAnchor.constraint(equalTo: inputTextView.bottomAnchor,
                                                                              constant: bottomAreaInset)
    inputBottomConstraint.isActive = true

    sendBottomConstraint = messageInputContainerView.bottomAnchor.constraint(equalTo: sendButton.bottomAnchor,
                                                                             constant: bottomAreaInset + 6)
    sendBottomConstraint.isActive = true

    messageInputContainerView.addConstraintsWithFormat(format: "V:|[v0(0.5)]|", views: topBorderView)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    inputTextView.becomeFirstResponder()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if let spinner = spinner {
      removeSpinner(spinner)
    }
    inputTextView.endEditing(true)
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    sendButton.isEnabled = false
    heightConstraint.constant = 88 + bottomAreaInset
  }

  func textViewDidChange(_ textView: UITextView) {
    sendButton.isEnabled = !textView.text.isEmpty
    let size = CGSize(width: view.frame.width - 60, height: .infinity)
    let estimatedSize = textView.sizeThatFits(size)
    heightConstraint.constant = estimatedSize.height + 54 + (self.isKeyboardShown ? 0 : bottomAreaInset)
  }

  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    if(text == "\n") {
      textView.resignFirstResponder()
      return true
    }
    return true
  }

  @objc func tagSelected(_ tag: MDCChipView) {
    guard let title = tag.titleLabel.text else { return }
    inputTextView.insertText(title)
  }

  @objc func handleKeyboardNotification(notification: NSNotification) {
    guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
      as? NSValue)?.cgRectValue else { return }
    let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
    guard self.isKeyboardShown != isKeyboardShowing else {
      bottomConstraint?.constant = isKeyboardShowing ? -keyboardSize.height : 0
      return
    }
    self.isKeyboardShown = isKeyboardShowing
    bottomConstraint?.constant = isKeyboardShowing ? -keyboardSize.height : 0
    let inset = isKeyboardShowing ? -bottomAreaInset : bottomAreaInset
    heightConstraint?.constant += inset
    inputBottomConstraint?.constant = isKeyboardShowing ? 0 : bottomAreaInset
    sendBottomConstraint?.constant = isKeyboardShowing ? 6 : (6 + bottomAreaInset)
    if let animationDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
      UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
        self.view.layoutIfNeeded()
      }, completion: nil)
    }
  }

  func textViewDidBeginEditing(_ textView: UITextView) {
    textViewDidChange(textView)
  }


  func detectLabelsInImage() {
    self.vision = Vision.vision()
    let options = VisionCloudImageLabelerOptions()
    options.confidenceThreshold = 0.7
    let imageLabeler = vision.cloudImageLabeler(options: options)
    let imageMetadata = VisionImageMetadata()
    imageMetadata.orientation = FPUploadViewController.visionImageOrientation(from: image.imageOrientation)
    let visionImage = VisionImage(image: image)
    visionImage.metadata = imageMetadata

    imageLabeler.process(visionImage) { labels, error in
      guard error == nil, let labels = labels, !labels.isEmpty else {
        return
      }

      labels.prefix(3).forEach {
        let chip = MDCChipView()
        chip.titleLabel.text = "#" + $0.text.components(separatedBy: .whitespaces).joined(separator: "_")
        chip.sizeToFit()
        chip.addTarget(self, action: #selector(self.tagSelected(_:)), for: .touchUpInside)
        self.smartTagsView.addArrangedSubview(chip)
      }
    }
  }

  public static func visionImageOrientation(
    from imageOrientation: UIImage.Orientation
    ) -> VisionDetectorImageOrientation {
    switch imageOrientation {
    case .up:
      return .topLeft
    case .down:
      return .bottomRight
    case .left:
      return .leftBottom
    case .right:
      return .rightTop
    case .upMirrored:
      return .topRight
    case .downMirrored:
      return .bottomLeft
    case .leftMirrored:
      return .leftTop
    case .rightMirrored:
      return .rightBottom
    }
  }

  @IBAction func uploadPressed(_ sender: Any) {
    spinner = displaySpinner()
    button.isEnabled = false
    inputTextView.endEditing(true)
    let postRef = database.reference(withPath: "posts").childByAutoId()
    guard let postId = postRef.key else { return }
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

      let trimmedComment = self.inputTextView.text?.trimmingCharacters(in: CharacterSet.whitespaces)
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
