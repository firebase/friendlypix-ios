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

class FPAccountViewController: FPFeedViewController {

  var user: FPUser!
  var headerView: FPCollectionReusableView!


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

  @IBAction func valueChanged(_ sender: Any) {
    if user.userID == uid {
      headerView.followSwitch.isOn ? enableNotifications() : disableNotifications()
    }

    headerView.followSwitch.isOn ? follow() : unfollow()
  }

  override func loadData() {
    super.ref.child("people").child(user.userID).observeSingleEvent(of: .value, with: { userSnapshot in
      let followingCount = userSnapshot.childSnapshot(forPath: "following").childrenCount
      self.headerView.followingLabel.text = "\(followingCount) following"

      if self.user.userID == self.uid {

      }

      if let posts =  userSnapshot.childSnapshot(forPath: "posts").value as? [String:Any] {
        let postCount = posts.count
        self.headerView.postsLabel.text = "\(postCount) post\(postCount == 1 ? "" : "s")"
        for postId in posts.keys {
          super.ref.child("posts/" + (postId)).observe(.value, with: { postSnapshot in
            super.loadPost(postSnapshot)
          })
        }
      }
    })
    super.ref.child("followers").child(user.userID).observeSingleEvent(of: .value, with: { snapshot in
      if let followers = snapshot.value as? [String: Any] {
        let followersCount = followers.count
        self.headerView.followersLabel.text = "\(followersCount) follower\(followersCount == 1 ? "" : "s")"
        // check if the currentUser is following this user
        self.headerView.followSwitch.isOn = followers[self.uid] != nil ? true : false
      }
    })
  }

  func follow() {
    let myFeed = super.ref.child("feed/\(uid)")
    super.ref.child("people/\(user.userID)/posts").observeSingleEvent(of: .value, with: { snapshot in
      var lastPostID: Any = true
      let posts = snapshot.value as! [String:Any]
      for postId in posts.keys {
        myFeed.child(postId).setValue(true)
        lastPostID = postId
      }
      super.ref.updateChildValues(["followers/\(self.user.userID)/\(self.uid)": lastPostID, "people/\(self.uid)/following/\(self.user.userID)": true])
    })
  }

  func unfollow() {
    let myFeed = super.ref.child("feed/\(uid)")
    super.ref.child("people/\(user.userID)/posts").observeSingleEvent(of: .value, with: { snapshot in
      let posts = snapshot.value as! [String:Any]
      for postId in posts.keys {
        myFeed.child(postId).removeValue()
      }
      super.ref.updateChildValues(["followers/\(self.user.userID)/\(self.uid)": NSNull(), "people/\(self.uid)/following/\(self.user.userID)": NSNull()])
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
