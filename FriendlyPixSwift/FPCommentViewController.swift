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

class FPCommentViewController: MDCCollectionViewController, UITextFieldDelegate {
  var post: FPPost!

    override func viewDidLoad() {
      super.viewDidLoad()
      styler.cellStyle = .card
    }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return post.comments.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)

    if let textCell = cell as? MDCCollectionViewTextCell {
      let comment = post.comments[indexPath.item]
      textCell.textLabel?.text = "\(comment.from!.fullname): \(comment.text)"
      UIImage.circleImage(from: comment.from!.profilePictureURL, to: textCell.imageView!)
    }
    
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    if kind == UICollectionElementKindSectionFooter {
      let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "FooterView", for: indexPath) as! FPFooterView
      navigationItem.title = "Comments"
      footerView.commentField.delegate = self
      let textFieldControllerFloating = MDCTextInputControllerDefault(textInput: footerView.commentField)
      return footerView
    }
    return UICollectionReusableView.init()
  }

  @objc override func collectionView(_ collectionView: UICollectionView, layout  collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize{
    let size = CGSize(width: collectionView.frame.size.width, height: 80)
    return size
  }
}
