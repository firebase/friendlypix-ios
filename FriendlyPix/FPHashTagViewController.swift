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
import MaterialComponents

class FPHashTagViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
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
    navigationItem.title = "#\(hashtag)"
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return postSnapshots.count
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    loadData()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    for firebaseRef in firebaseRefs {
      firebaseRef.removeAllObservers()
    }
    firebaseRefs = [DatabaseReference]()
  }

  func registerForPostsDeletion() {
    let userPostsRef = database.reference(withPath: "hashtags/\(hashtag)")
    userPostsRef.observe(.childRemoved, with: { postSnapshot in
      var index = 0
      for post in self.postSnapshots {
        if post.key == postSnapshot.key {
          self.postSnapshots.remove(at: index)
          self.loadingPostCount -= 1
          self.collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
          return
        }
        index += 1
      }
      self.postIds?.removeValue(forKey: postSnapshot.key)
    })
  }


  func loadUserPosts() {
    database.reference(withPath: "hashtags/\(hashtag.lowercased())").observeSingleEvent(of: .value, with: {
      if var posts = $0.value as? [String: Any] {
        if !self.postSnapshots.isEmpty {
          var index = self.postSnapshots.count - 1
          self.collectionView?.performBatchUpdates({
            for post in self.postSnapshots.reversed() {
              if posts.removeValue(forKey: post.key) == nil {
                self.postSnapshots.remove(at: index)
                self.collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
                return
              }
              index -= 1
            }
          }, completion: nil)
          self.postIds = posts
          self.loadingPostCount = posts.count
        } else {
          self.postIds = posts
          self.loadFeed()
        }
        self.registerForPostsDeletion()
      }
    })
  }

  func loadData() {
    loadUserPosts()
  }

  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
    if indexPath.item == (loadingPostCount - 3) {
      loadFeed()
    }
  }

  func loadFeed() {
    loadingPostCount = postSnapshots.count + 12
    self.collectionView?.performBatchUpdates({
      for _ in 1...12 {
        if let postId = self.postIds?.popFirst()?.key {
          database.reference(withPath: "posts/\(postId)").observeSingleEvent(of: .value, with: { postSnapshot in
            self.postSnapshots.append(postSnapshot)
            self.collectionView?.insertItems(at: [IndexPath(item: self.postSnapshots.count - 1, section: 0)])
          })
        } else {
          break
        }
      }
    }, completion: nil)
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

  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let height = MDCCeil(((self.collectionView.bounds.width) - 14) * 0.325)
    return CGSize(width: height, height: height)
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
