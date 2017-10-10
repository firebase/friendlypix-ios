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

  @IBOutlet weak var postsLabel: UILabel!
  @IBOutlet weak var followingLabel: UILabel!
  @IBOutlet weak var followersLabel: UILabel!
  @IBOutlet weak var profilePictureImageView: UIImageView!
  var user: FPUser!

  override func loadData() {
    super.ref.child("people").child(user.userID).observeSingleEvent(of: .value, with: { userSnapshot in
      let followingCount = userSnapshot.childSnapshot(forPath: "following").childrenCount
      self.followingLabel.text = "\(followingCount) following"

      self.navigationItem.title = self.user.fullname

      if !(self.user.userID == self.uid) {
        let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        loadingActivityIndicatorView.startAnimating()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
      }

      if let posts =  userSnapshot.childSnapshot(forPath: "posts").value as? [String] {
        let postCount = posts.count
        self.postsLabel.text = "\(postCount) post\(postCount == 1 ? "" : "s")"
        for postId in posts {
          super.ref.child("posts/" + (postId)).observe(.value, with: { postSnapshot in
            super.loadPost(postSnapshot)
          })
        }
      }
    })
    super.ref.child("followers").child(user.userID).observeSingleEvent(of: .value, with: { snapshot in
      if let followers = snapshot.value as? [String: Any] {
        let followersCount = followers.count
        self.followersLabel.text = "\(followersCount) follower\(followersCount == 1 ? "" : "s")"
        // check if the currentUser is following this user
        if followers[self.uid] != nil {
          self.configureUnfollowButton()
        }
        else {
          self.configureFollowButton()
        }
      }
    })
   // profilePictureImageView.setCircleImageWithURL(user.profilePictureURL, placeholderImage: UIImage(named: "PlaceholderPhoto"))
  }

  // MARK: - ()
  @objc func followButtonAction(_ sender: Any) {
    let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
    loadingActivityIndicatorView.startAnimating()
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
    let myFeed = super.ref.child("feed/\(uid)")
    super.ref.child("people/\(user.userID)/posts").observeSingleEvent(of: .value, with: { snapshot in
      var lastPostID: Any = true
      for postId: String in snapshot.value as! [String] {
        myFeed.child(postId).setValue(true)
        lastPostID = postId
      }
      super.ref.updateChildValues(["followers/\(self.user.userID)/\(self.uid)": lastPostID, "people/\(self.uid)/following/\(self.user.userID)": true])
    })
    configureUnfollowButton()
  }

  @objc func unfollowButtonAction(_ sender: Any) {
    let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
    loadingActivityIndicatorView.startAnimating()
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
    let myFeed = super.ref.child("feed/\(uid)")
    super.ref.child("people/\(user.userID)/posts").observeSingleEvent(of: .value, with: { snapshot in
      let posts = snapshot.value as? [String]
      for postId in posts! {
        myFeed.child(postId).removeValue()
      }
      super.ref.updateChildValues(["followers/\(self.user.userID)/\(self.uid)": NSNull(), "people/\(self.uid)/following/\(self.user.userID)": NSNull()])
    })
    configureFollowButton()
  }

  func backButtonAction(_ sender: Any) {
    navigationController?.popViewController(animated: true)
  }

  func configureFollowButton() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Follow", style: .plain, target: self, action: #selector(self.followButtonAction))
  }

  func configureUnfollowButton() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unfollow", style: .plain, target: self, action: #selector(self.unfollowButtonAction))
  }
}
