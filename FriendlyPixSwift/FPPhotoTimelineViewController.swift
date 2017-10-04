//
//  FirstViewController.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 9/29/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialCollections
import Firebase

class FPPhotoTimelineViewController: MDCCollectionViewController {

  var ref: DatabaseReference!
  var postsRef: DatabaseReference!
  var commentsRef: DatabaseReference!
  var likesRef: DatabaseReference!
  var query: DatabaseReference!
  var posts = [FPPost]()
  var loadingPostCount: UInt = 0
  var layout: MDCCollectionViewFlowLayout?

  let MAX_NUMBER_OF_COMMENTS = 3

  override func viewDidLoad() {
    super.viewDidLoad()
    layout = MDCCollectionViewFlowLayout.init()
    layout?.estimatedItemSize = CGSize.init(width: 1, height: 1)


    self.styler.cellStyle = .card
    //self.styler.cellLayoutType = .grid
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

  func loadFeed(_ earliestEntryId: String?) {
    var query = self.query?.queryOrderedByKey()
    var i = 0
    if let earliestEntryId = earliestEntryId {
      query = query?.queryEnding(atValue: earliestEntryId)
      i = 1
    }
    loadingPostCount += 6
    query?.queryLimited(toLast: 6).observeSingleEvent(of: .value, with: {(_ snapshot: DataSnapshot) -> Void in
      let reversed = snapshot.children.allObjects
      for index in stride(from: reversed.count-1, through: i, by: -1) {
        self.loadItem(reversed[index] as! DataSnapshot)
      }
    })
    postsRef.observe(.childRemoved, with: {(_ postSnapshot: DataSnapshot) -> Void in
      var index = 0
      for post in self.posts {
        if post.postID == postSnapshot.key {
          break
        }
        index += 1
      }
      self.posts.remove(at: index)
      self.collectionView?.deleteItems(at: [IndexPath.init(row: index, section: 0)])
    })
  }

  func loadPost(_ postSnapshot: DataSnapshot) {
    commentsRef.child(postSnapshot.key).observe(.value, with: {(_ commentsSnapshot: DataSnapshot) -> Void in
      var commentsArray = Array<FPComment?>(repeating: nil, count: Int(commentsSnapshot.childrenCount))
      for commentSnapshot in commentsSnapshot.children {
        let comment = FPComment(snapshot: commentSnapshot as! DataSnapshot)
        commentsArray.append(comment)
      }
      self.likesRef.child(postSnapshot.key).observeSingleEvent(of: .value, with: {(_ snapshot: DataSnapshot) -> Void in
        let post = FPPost(snapshot: postSnapshot, andComments: commentsArray)
        if let likes = snapshot.value {
          //post.likes = likes as! [String : String]
        }
        else {
          //post.likes = [String: String]()
        }
        self.posts.append(post)
        self.collectionView?.insertItems(at: [IndexPath.init(row: self.posts.count-1, section: 0)])
        self.layout?.invalidateLayout()
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

//  override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
//    return 200
//  }


  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FPCardCollectionViewCell
    let post = posts[indexPath.row]
    cell.populateContent(author: (post.author?.fullname)!, authorURL: (post.author?.profilePictureURL)!, date: post.postDate!, imageURL: post.imageURL!, title: post.text, likes: 0)
    return cell
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

