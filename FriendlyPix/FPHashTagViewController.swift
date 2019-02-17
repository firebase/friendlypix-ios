//
//  Copyright (c) 2018 Google Inc.
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
import Lightbox
import MaterialComponents.MaterialCollections

class FPHashTagViewController: MDCCollectionViewController {
  var hashtag = ""
  let uid = Auth.auth().currentUser!.uid
  let database = Database.database()
  let ref = Database.database().reference()
  var postIds: [String: Any]?
  var postSnapshots = [DataSnapshot]()
  var loadingPostCount = 0
  var firebaseRefs = [DatabaseReference]()
  lazy var appDelegate = UIApplication.shared.delegate as! AppDelegate

  override func viewDidLoad() {
    super.viewDidLoad()
    self.styler.cellStyle = .card
    self.styler.cellLayoutType = .grid
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return postSnapshots.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    let postSnapshot = postSnapshots[indexPath.item]
    if let value = postSnapshot.value as? [String: Any], let photoUrl = value["thumb_url"] as? String {
      let imageView = UIImageView()
      cell.backgroundView = imageView
      imageView.sd_setImage(with: URL(string: photoUrl), completed: nil)
      imageView.contentMode = .scaleAspectFill
      imageView.isAccessibilityElement = true
      imageView.accessibilityLabel = "Photo with hashtag \(hashtag)"
    }
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
    return MDCCeil(((self.collectionView?.bounds.width)! - 14) * 0.325)
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    performSegue(withIdentifier: "detail", sender: postSnapshots[indexPath.item])
  }

  func backButtonAction(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "detail" {
      if let detailViewController = segue.destination as? FPPostDetailViewController,
        let sender = sender as? DataSnapshot {
        detailViewController.postSnapshot = sender
      }
    }
  }
}
