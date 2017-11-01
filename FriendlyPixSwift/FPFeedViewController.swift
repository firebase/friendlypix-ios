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

class FPFeedViewController: MDCCollectionViewController, FPCardCollectionViewCellDelegate {

  let uid = Auth.auth().currentUser!.uid

  var ref: DatabaseReference!
  var postsRef: DatabaseReference!
  var commentsRef: DatabaseReference!
  var likesRef: DatabaseReference!
  var query: DatabaseReference!
  var posts = [FPPost]()
  var loadingPostCount = 0
  var sizingNibNew: FPCardCollectionViewCell!

  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = UINib(nibName: "FPCardCollectionViewCell", bundle: nil)

    guard let collectionView = collectionView else {
      return
    }
    collectionView.register(nib, forCellWithReuseIdentifier: "cell")
    sizingNibNew = Bundle.main.loadNibNamed("FPCardCollectionViewCell", owner: self, options: nil)?[0] as! FPCardCollectionViewCell

    self.styler.cellStyle = .card
    let insets = self.collectionView(collectionView,
                                     layout: collectionViewLayout,
                                     insetForSectionAt: 0)
    let cellFrame = CGRect(x: 0, y: 0, width: collectionView.bounds.width - insets.left - insets.right, height: collectionView.bounds.height)
    sizingNibNew.frame = cellFrame

  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    ref = Database.database().reference()
    postsRef = ref.child("posts")
    commentsRef = ref.child("comments")
    likesRef = ref.child("likes")
    loadingPostCount = 0
    loadData()
  }

  func loadData() {
    query = postsRef
    loadFeed(nil)
  }

  func loadItem(_ item: DataSnapshot) {
    loadPost(item)
  }

  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

    if indexPath.item == (loadingPostCount - 1) {
      loadFeed(posts[indexPath.item].postID)
    }
  }

  func loadFeed(_ earliestEntryId: String?) {
    var query = self.query?.queryOrderedByKey()
    var i = 0
    if let earliestEntryId = earliestEntryId {
      query = query?.queryEnding(atValue: earliestEntryId)
      i = 1
    }
    loadingPostCount += 6
    query?.queryLimited(toLast: 6).observeSingleEvent(of: .value, with: { snapshot in
      let reversed = snapshot.children.allObjects
      for index in stride(from: reversed.count-1, through: i, by: -1) {
        self.loadItem(reversed[index] as! DataSnapshot)
      }
    })
    postsRef.observe(.childRemoved, with: { postSnapshot in
      var index = 0
      for post in self.posts {
        if post.postID == postSnapshot.key {
          break
        }
        index += 1
      }
      self.posts.remove(at: index)
      self.collectionView?.deleteItems(at: [IndexPath.init(item: index, section: 0)])
    })
  }

  func loadPost(_ postSnapshot: DataSnapshot) {
    commentsRef.child(postSnapshot.key).observe(.value, with: { commentsSnapshot in
      var commentsArray = [FPComment]()
      for commentSnapshot in commentsSnapshot.children {
        let comment = FPComment(snapshot: commentSnapshot as! DataSnapshot)
        commentsArray.append(comment)
      }
      self.likesRef.child(postSnapshot.key).observeSingleEvent(of: .value, with: { snapshot in
        let post = FPPost(snapshot: postSnapshot, andComments: commentsArray)
        if let likes = snapshot.value {
          //post.likes = likes as! [String : String]
        }
        else {
          //post.likes = [String: String]()
        }
        self.posts.append(post)
        self.collectionView?.insertItems(at: [IndexPath.init(item: self.posts.count-1, section: 0)])
      })
    })
  }

  override func viewWillDisappear(_ animated: Bool) {
    ref.removeAllObservers()
  }

  // MARK: UICollectionViewDataSource

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return posts.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FPCardCollectionViewCell
    let post = posts[indexPath.item]
    cell.populateContent(post: post, isDryRun: false)
    cell.delegate = self
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
    let post = posts[indexPath.item]
    sizingNibNew.populateContent(post: post, isDryRun: true)

    sizingNibNew.setNeedsUpdateConstraints()
    sizingNibNew.updateConstraintsIfNeeded()
    sizingNibNew.contentView.setNeedsLayout()
    sizingNibNew.contentView.layoutIfNeeded()

    var fittingSize = UILayoutFittingCompressedSize
    fittingSize.width = sizingNibNew.frame.width

    let size = sizingNibNew.contentView.systemLayoutSizeFitting(fittingSize)
    return size.height
  }

  func clickUser() {
    showProfile(FPCurrentUser.shared.user)
  }

  func showProfile(_ author: FPUser) {
    performSegue(withIdentifier: "account", sender: author)
  }

  func viewComments(_ post: FPPost) {
    performSegue(withIdentifier: "comment", sender: post)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if (segue.identifier == "account") {
      if let accountViewController = segue.destination as? FPAccountViewController {
        accountViewController.user = sender as! FPUser
      }
    }
    else if (segue.identifier == "comment") {
      if let commentViewController = segue.destination as? FPCommentViewController {
       commentViewController.post = sender as! FPPost
      }
    }
  }

}

