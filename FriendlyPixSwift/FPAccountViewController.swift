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

class FPAccountViewController: MDCCollectionViewController {

  var user: FPUser!
  var headerView: FPCollectionReusableView!
  let uid = Auth.auth().currentUser!.uid
  var ref: DatabaseReference!
  var postIds: [String:Any]?
  var photos = [String]()
  var loadingPostCount = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    self.styler.cellStyle = .card
    self.styler.cellLayoutType = .grid
    self.styler.gridColumnCount = 3
  }


  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    if kind == UICollectionElementKindSectionHeader {
      headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "HeaderView", for: indexPath) as! FPCollectionReusableView
      navigationItem.title = self.user.fullname
      if user.userID == uid {
        headerView.followLabel.text = "Enable notifications"
        // headerView.followSwitch.isOn = user.isEnabledNotifications
      }
      UIImage.circleImage(from: user.profilePictureURL, to: headerView.profilePictureImageView)
      return headerView
    }
    return UICollectionReusableView.init()
  }

  @objc override func collectionView(_ collectionView: UICollectionView, layout  collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
    let size = CGSize(width: collectionView.frame.size.width, height: 80)
    return size
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    ref = Database.database().reference()
    loadData()
  }

  @IBAction func valueChanged(_ sender: Any) {
    if user.userID == uid {
      headerView.followSwitch.isOn ? enableNotifications() : disableNotifications()
    }

    headerView.followSwitch.isOn ? follow() : unfollow()
  }

  func loadData() {
    ref.child("people").child(user.userID).observeSingleEvent(of: .value, with: { userSnapshot in
      let followingCount = userSnapshot.childSnapshot(forPath: "following").childrenCount
      self.headerView.followingLabel.text = "\(followingCount) following"

      if self.user.userID == self.uid {

      }

      if let posts =  userSnapshot.childSnapshot(forPath: "posts").value as? [String:Any] {
        self.postIds = posts
        let postCount = posts.count
        self.headerView.postsLabel.text = "\(postCount) post\(postCount == 1 ? "" : "s")"
        self.loadFeed()
      }
    })
    ref.child("followers").child(user.userID).observeSingleEvent(of: .value, with: { snapshot in
      if let followers = snapshot.value as? [String: Any] {
        let followersCount = followers.count
        self.headerView.followersLabel.text = "\(followersCount) follower\(followersCount == 1 ? "" : "s")"
        // check if the currentUser is following this user
        self.headerView.followSwitch.isOn = followers[self.uid] != nil ? true : false
      }
    })
  }

  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if indexPath.item == (loadingPostCount - 1) {
      loadFeed()
    }
  }

  func loadFeed() {
    loadingPostCount += 18
    for _ in 1...18 {
      if let postId = self.postIds?.popFirst()?.key {
        self.ref.child("posts/" + (postId)).observe(.value, with: { postSnapshot in
          let value = postSnapshot.value as! [String:Any]
          self.photos.append(value["full_url"] as? String ?? value["url"]! as! String)
          self.collectionView?.insertItems(at: [IndexPath.init(item: self.photos.count-1, section: 0)])
        })
      } else {
        break
      }
    }
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! UICollectionViewCell
    let x = UIImageView.init()
    cell.backgroundView = x
    x.sd_setImage(with: URL(string: photos[indexPath.item]), completed:{ (img, error, cacheType, imageURL) in
      // Handle image being set
    })
    return cell
  }

  func follow() {
    let myFeed = ref.child("feed/\(uid)")
    ref.child("people/\(user.userID)/posts").observeSingleEvent(of: .value, with: { snapshot in
      var lastPostID: Any = true
      let posts = snapshot.value as! [String:Any]
      for postId in posts.keys {
        myFeed.child(postId).setValue(true)
        lastPostID = postId
      }
      self.ref.updateChildValues(["followers/\(self.user.userID)/\(self.uid)": lastPostID, "people/\(self.uid)/following/\(self.user.userID)": true])
    })
  }

  override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
    return MDCCeil(((self.collectionView?.bounds.width)! - 2) * 0.25)
  }

  func unfollow() {
    let myFeed = ref.child("feed/\(uid)")
    ref.child("people/\(user.userID)/posts").observeSingleEvent(of: .value, with: { snapshot in
      let posts = snapshot.value as! [String:Any]
      for postId in posts.keys {
        myFeed.child(postId).removeValue()
      }
      self.ref.updateChildValues(["followers/\(self.user.userID)/\(self.uid)": NSNull(), "people/\(self.uid)/following/\(self.user.userID)": NSNull()])
    })
  }

  func enableNotifications() {
  }

  func disableNotifications() {
  }

  func backButtonAction(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }
}
