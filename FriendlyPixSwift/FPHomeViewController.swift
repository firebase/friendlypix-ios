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

class FPHomeViewController: FPFeedViewController {

  override func loadData() {
    query = ref.child("feed").child(uid)
    // Make sure the home feed is updated with followed users's new posts.
    // Only after the feed creation is complete, start fetching the posts.
    updateHomeFeeds()
  }

  func getHomeFeedPosts() {
    loadFeed(nil)
  }

  override func loadItem(_ item: DataSnapshot) {
    super.ref.child("posts/" + (item.key)).observe(.value) { postSnapshot in
      super.loadPost(postSnapshot)
    }
  }

  /**
   * Keeps the home feed populated with latest followed users' posts live.
   */
  func startHomeFeedLiveUpdaters() {
    // Make sure we listen on each followed people's posts.
    let followingRef = super.ref.child("people").child(uid).child("following")
    followingRef.observe(.childAdded, with: { followingSnapshot in
      // Start listening the followed user's posts to populate the home feed.
      let followedUid = followingSnapshot.key
      var followedUserPostsRef: DatabaseQuery = super.ref.child("people").child(followedUid).child("posts")
      if followingSnapshot.exists() && (followingSnapshot.value is String) {
        followedUserPostsRef = followedUserPostsRef.queryOrderedByKey().queryStarting(atValue: followingSnapshot.value)
      }
      followedUserPostsRef.observe(.childAdded, with: { postSnapshot in
        if postSnapshot.key != followingSnapshot.key {
          let updates = ["/feed/\(self.uid)/\(postSnapshot.key)": true,
                         "/people/\(self.uid)/following/\(followedUid)": postSnapshot.key] as [String: Any]
          super.ref.updateChildValues(updates)
        }
      })
    })
    // Stop listening to users we unfollow.
    followingRef.observe(.childRemoved, with: { snapshot in
      // Stop listening the followed user's posts to populate the home feed.
      let followedUserId: String = snapshot.key
      super.ref.child("people").child(followedUserId).child("posts").removeAllObservers()
    })
  }

  /**
   * Updates the home feed with new followed users' posts and returns a promise once that's done.
   */
  func updateHomeFeeds() {
    // Make sure we listen on each followed people's posts.
    let followingRef = super.ref.child("people").child(uid).child("following")
    followingRef.observeSingleEvent(of: .value, with: { followingSnapshot in
      // Start listening the followed user's posts to populate the home feed.
      guard let following = followingSnapshot.value as? [String: Any] else {
        self.startHomeFeedLiveUpdaters()
        // Get home feed posts
        self.getHomeFeedPosts()
        return
      }
      var followedUserPostsRef: DatabaseQuery!
      for (followedUid, lastSyncedPostId) in following {
        followedUserPostsRef = super.ref.child("people").child(followedUid).child("posts")
        var lastSyncedPost = ""
        if let lastSyncedPostId = lastSyncedPostId as? String {
          followedUserPostsRef = followedUserPostsRef.queryOrderedByKey().queryStarting(atValue: lastSyncedPostId)
          lastSyncedPost = lastSyncedPostId
        }
        followedUserPostsRef.observeSingleEvent(of: .value, with: { postSnapshot in
          if let postArray = postSnapshot.value as? [String: Any] {
            var updates = [AnyHashable: Any]()
            for postId in postArray.keys where postId != lastSyncedPost {
                updates["/feed/\(self.uid)/\(postId)"] = true
                updates["/people/\(self.uid)/following/\(followedUid)"] = postId
            }
            super.ref.updateChildValues(updates)
          }
          // Add new posts from followers live.
          self.startHomeFeedLiveUpdaters()
          // Get home feed posts
          self.getHomeFeedPosts()
        })
      }
    })
  }
}
