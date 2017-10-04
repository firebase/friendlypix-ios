//
//  FPAccountViewController.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 10/3/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialCollections
import Firebase

class FPAccountViewController: FPPhotoTimelineViewController {
  var user: FPUser!

//  override func loadData() {
//    super.ref.child("people").child(user.userID).observeSingleEvent(of: .value, with: {(_ userSnapshot: DataSnapshot) -> Void in
//      let posts = userSnapshot.childSnapshot(forPath: "posts").value
//      followingCount = userSnapshot.childSnapshot(forPath: "following").childrenCount
//      self.feedDidLoad()
//      if posts && !posts.isEqual(NSNull()) {
//        postCount = posts.count
//        for postId: String in posts {
//          super.ref.child("posts/" + (postId)).observeEventType(.value, with: {(_ postSnapshot: DataSnapshot) -> Void in
//            super.loadPost(postSnapshot)
//          })
//        }
//      }
//      else {
//        postCount = 0
//      }
//    })
//    super.ref.child("followers").child(user.userID).observeSingleEvent(of: .value, with: {(_ snapshot: DataSnapshot) -> Void in
//      followers = snapshot.value
//      if followers {
//        let followersCount: UInt = (followers && !followers.isEqual(NSNull())) ? followers.count : 0
//        followerCountLabel.text = "\(followersCount) follower\(followersCount == 1 ? "" : "s")"
//      }
//    })
//    profilePictureImageView.setCircleImageWithURL(user.profilePictureURL, placeholderImage: UIImage(named: "PlaceholderPhoto"))
//  }
//
//  // MARK: - UIViewController
//  func feedDidLoad() {
//    navigationItem?.title = user.username
//    photoCountLabel.text = "\(postCount) post\(postCount == 1 ? "" : "s")"
//    followingCountLabel.text = "\(followingCount) following"
//    if !(user.userID == FPAppState.sharedInstance().isCurrentUser.userID) {
//      let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
//      loadingActivityIndicatorView.startAnimating()
//      navigationItem?.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
//      // check if the currentUser is following this user
//      if followers[FPAppState.sharedInstance().isCurrentUser.userID] {
//        configureUnfollowButton()
//      }
//      else {
//        configureFollowButton()
//      }
//    }
//  }
//
//  // MARK: - ()
//  func followButtonAction(_ sender: Any) {
//    let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
//    loadingActivityIndicatorView.startAnimating()
//    navigationItem?.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
//    let myFeed: DatabaseReference? = super.ref.child("feed/\(FPAppState.sharedInstance().isCurrentUser.userID)")
//    super.ref.child("people/\(user.userID)/posts").observeSingleEventOfType(.value, with: {(_ snapshot: DataSnapshot) -> Void in
//      var lastPostID = true as? String
//      for postId: String in snapshot.value.keys {
//        myFeed?.child(postId)?.value = true
//        lastPostID = postId
//      }
//      super.ref.updateChildValues(["followers/\(user.userID)/\(FPAppState.sharedInstance().isCurrentUser.userID)": lastPostID, "people/\(FPAppState.sharedInstance().isCurrentUser.userID)/following/\(user.userID)": true])
//    })
//    configureUnfollowButton()
//  }
//
//  func unfollowButtonAction(_ sender: Any) {
//    let loadingActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
//    loadingActivityIndicatorView.startAnimating()
//    navigationItem?.rightBarButtonItem = UIBarButtonItem(customView: loadingActivityIndicatorView)
//    let myFeed = super.ref.child("feed/\(FPAppState.sharedInstance().isCurrentUser.userID)")
//    super.ref.child("people/\(user.userID)/posts").observeSingleEventOfType(.value, with: {(_ snapshot: DataSnapshot) -> Void in
//      for postId: String in snapshot.value.keys {
//        myFeed?.child(postId)?.removeValue()
//      }
//      super.ref.updateChildValues(["followers/\(user.userID)/\(FPAppState.sharedInstance().isCurrentUser.userID)": NSNull(), "people/\(FPAppState.sharedInstance().isCurrentUser.userID)/following/\(user.userID)": NSNull()])
//    })
//    configureFollowButton()
//  }
//
//  func backButtonAction(_ sender: Any) {
//    navigationController?.popViewController(animated: true)
//  }
//
//  func configureFollowButton() {
//    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Follow", style: .plain, target: self, action: #selector(self.followButtonAction))
//  }
//
//  func configureUnfollowButton() {
//    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Unfollow", style: .plain, target: self, action: #selector(self.unfollowButtonAction))
//  }
}
