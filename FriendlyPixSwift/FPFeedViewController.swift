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
import MaterialComponents

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
    sizingNibNew = Bundle.main.loadNibNamed("FPCardCollectionViewCell", owner: self, options: nil)?[0]
      as? FPCardCollectionViewCell

    self.styler.cellStyle = .card
    let insets = self.collectionView(collectionView,
                                     layout: collectionViewLayout,
                                     insetForSectionAt: 0)
    let cellFrame = CGRect(x: 0, y: 0, width: collectionView.bounds.width - insets.left - insets.right,
                           height: collectionView.bounds.height)
    sizingNibNew.frame = cellFrame
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    ref = Database.database().reference()
    postsRef = ref.child("posts")
    commentsRef = ref.child("comments")
    likesRef = ref.child("likes")
    loadingPostCount = 0
    if (posts.isEmpty) {
      loadData()
    }
  }

  func loadData() {
    query = postsRef
    loadFeed(nil)
  }

  func loadItem(_ item: DataSnapshot) {
    loadPost(item)
  }

  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
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
      if let reversed = snapshot.children.allObjects as? [DataSnapshot] {
        self.collectionView?.performBatchUpdates({
          for index in stride(from: reversed.count - 1, through: i, by: -1) {
            self.loadItem(reversed[index])
          }
        }, completion: nil)
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
      self.collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
    })
  }

  func loadPost(_ postSnapshot: DataSnapshot) {
    let postId = postSnapshot.key
    commentsRef.child(postId).observe(.value, with: { commentsSnapshot in
      var commentsArray = [FPComment]()
      let enumerator = commentsSnapshot.children
      while let commentSnapshot = enumerator.nextObject() as? DataSnapshot {
        let comment = FPComment(snapshot: commentSnapshot)
        commentsArray.append(comment)
      }
      self.likesRef.child(postId).observeSingleEvent(of: .value, with: { snapshot in
        let likes = snapshot.value as? [String: Any]
        let post = FPPost(snapshot: postSnapshot, andComments: commentsArray, andLikes: likes)
        self.posts.append(post)
        self.collectionView?.insertItems(at: [IndexPath(item: self.posts.count - 1, section: 0)])
      })
    })
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    ref.removeAllObservers()
  }

  // MARK: UICollectionViewDataSource

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return posts.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    if let cell = cell as? FPCardCollectionViewCell {
      let post = posts[indexPath.item]
      cell.populateContent(post: post, isDryRun: false)
      cell.delegate = self
    }
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
    showProfile(FPUser.currentUser())
  }

  func showProfile(_ profile: FPUser) {
    performSegue(withIdentifier: "account", sender: profile)
  }

  func viewComments(_ post: FPPost) {
    performSegue(withIdentifier: "comment", sender: post)
  }

  func toogleLike(_ post: FPPost, button: UIButton, label: UILabel) {
    let postLike = ref.child("likes/\(post.postID)/\(uid)")
    if post.isLiked {
      postLike.removeValue(completionBlock: { error, _ in
        if let error = error {
          print(error.localizedDescription)
          return
        }
        post.likeCount -= 1
        post.isLiked = false
        label.text = "\(post.likeCount) likes"
        button.setImage(#imageLiteral(resourceName: "ic_favorite_border"), for: .normal)
      })
    } else {
      postLike.setValue(ServerValue.timestamp(), withCompletionBlock: { error, _ in
        if let error = error {
          print(error.localizedDescription)
          return
        }
        post.likeCount += 1
        post.isLiked = true
        label.text = "\(post.likeCount) likes"
        button.setImage(#imageLiteral(resourceName: "ic_favorite"), for: .normal)
      })
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "account" {
      if let accountViewController = segue.destination as? FPAccountViewController, let profile = sender as? FPUser {
        accountViewController.profile = profile
      }
    } else if segue.identifier == "comment" {
      if let commentViewController = segue.destination as? FPCommentViewController, let post = sender as? FPPost {
       commentViewController.post = post
      }
    }
  }
}

extension MDCCollectionViewController {
  var feedViewController: FPFeedViewController? {
    guard let fpTabBarController = navigationController?.viewControllers[0] as? FPTabBarController else { return nil }
    return fpTabBarController.feedViewController
  }
}
