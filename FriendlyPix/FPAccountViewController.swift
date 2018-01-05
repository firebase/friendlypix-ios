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
import Lightbox
import MaterialComponents.MaterialCollections

class FPAccountViewController: MDCCollectionViewController {

  var profile: FPUser!
  var headerView: FPCollectionReusableView!
  let uid = Auth.auth().currentUser!.uid
  let ref = Database.database().reference()
  var postIds: [String: Any]?
  var postSnapshots = [DataSnapshot]()
  var loadingPostCount = 0
  var firebaseRefs = [DatabaseReference]()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.styler.cellStyle = .card
    self.styler.cellLayoutType = .grid
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

  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    if kind == UICollectionElementKindSectionHeader,
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                                       withReuseIdentifier: "HeaderView",
                                                                       for: indexPath) as? FPCollectionReusableView {
      self.headerView = headerView
      navigationItem.title = profile.fullname
      if profile.userID == uid {
        headerView.followLabel.text = "Enable notifications"
      }
      headerView.profilePictureImageView.sd_setImage(with: profile.profilePictureURL, completed: nil)
      return headerView
    }
    return UICollectionReusableView()

  }

  @objc override func collectionView(_ collectionView: UICollectionView,
                                     layout  collectionViewLayout: UICollectionViewLayout,
                                     referenceSizeForHeaderInSection section: Int) -> CGSize {
    let size = CGSize(width: collectionView.frame.size.width, height: 112)
    return size
  }

  @IBAction func didTapProfile(_ sender: Any) {
    let lightboxImages: [LightboxImage] = postSnapshots.flatMap {
      guard let value = $0.value as? [String:Any], let fullURL = (value["full_url"] as? String).flatMap(URL.init) else { return nil }
      return LightboxImage(imageURL: fullURL, text: "\(profile.fullname): \(value["text"] ?? "")")
    }

    let lightbox = LightboxController(images: lightboxImages)
    lightbox.dynamicBackground = true
    self.present(lightbox, animated: true, completion: nil)
  }

  @IBAction func valueChanged(_ sender: Any) {
    if profile.userID == uid {
      let notificationEnabled = ref.child("people/\(uid)/notificationEnabled")
      if headerView.followSwitch.isOn {
        notificationEnabled.setValue(true)
      } else {
        notificationEnabled.removeValue()
      }
      return
    }

    toggleFollow(headerView.followSwitch.isOn)
  }

  func registerToFollowStatusUpdate() {
    let followStatusRef = ref.child("people/\(uid)/following/\(profile.userID)")
    followStatusRef.observe(.value) {
      self.headerView.followSwitch.isOn = $0.exists()
    }
    firebaseRefs.append(followStatusRef)
  }

  func registerToNotificationEnabledStatusUpdate() {
    let notificationEnabledRef  = ref.child("people/\(uid)/notificationEnabled")
    notificationEnabledRef.observe(.value) {
      self.headerView.followSwitch.isOn = $0.exists()
    }
    firebaseRefs.append(notificationEnabledRef)
  }

  func registerForFollowersCount() {
    let followersRef = ref.child("followers/\(profile.userID)")
    followersRef.observe(.value, with: {
      self.headerView.followersLabel.text = "\($0.childrenCount)"
    })
    firebaseRefs.append(followersRef)
  }

  func registerForFollowingCount() {
    let followingRef = ref.child("people/\(profile.userID)/following")
    followingRef.observe(.value, with: {
      self.headerView.followingLabel.text = "\($0.childrenCount)"
    })
    firebaseRefs.append(followingRef)
  }

  func registerForPostsCount() {
    let userPostsRef = ref.child("people/\(profile.userID)/posts")
    userPostsRef.observe(.value, with: {
      self.headerView.postsLabel.text = "\($0.childrenCount)"
    })
  }

  func registerForPostsDeletion() {
    let userPostsRef = ref.child("people/\(profile.userID)/posts")
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
    ref.child("people/\(profile.userID)/posts").observeSingleEvent(of: .value, with: {
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
    if profile.userID == uid {
      registerToNotificationEnabledStatusUpdate()
    } else {
      registerToFollowStatusUpdate()
    }
    registerForFollowersCount()
    registerForFollowingCount()
    registerForPostsCount()
    loadUserPosts()
  }

  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
    if indexPath.item == (loadingPostCount - 3) {
      loadFeed()
    }
  }

  func loadFeed() {
    loadingPostCount = postSnapshots.count + 10
    self.collectionView?.performBatchUpdates({
      for _ in 1...10 {
        if let postId = self.postIds?.popFirst()?.key {
          self.ref.child("posts/" + (postId)).observeSingleEvent(of: .value, with: { postSnapshot in
            self.postSnapshots.append(postSnapshot)
            self.collectionView?.insertItems(at: [IndexPath(item: self.postSnapshots.count - 1, section: 0)])
          })
        } else {
          break
        }
      }
    }, completion: nil)
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return postSnapshots.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    let postSnapshot = postSnapshots[indexPath.item]
    if let value = postSnapshot.value as? [String: Any],
      let photoUrl = value["thumb_url"] as? String {
        let imageView = UIImageView()
        cell.backgroundView = imageView
        imageView.sd_setImage(with: URL(string: photoUrl), completed: nil)
    }
    return cell
  }

  func toggleFollow(_ follow: Bool) {
    let myFeed = "feed/\(uid)/"
    ref.child("people/\(profile.userID)/posts").observeSingleEvent(of: .value, with: { snapshot in
      var lastPostID: Any = true
      var updateData = [String: Any]()
      if let posts = snapshot.value as? [String: Any] {
        // Add/remove followed user's posts to the home feed.
        for postId in posts.keys {
          updateData[myFeed + postId] = follow ? true : NSNull()
          lastPostID = postId
        }

        // Add/remove followed user to the 'following' list.
        updateData["people/\(self.uid)/following/\(self.profile.userID)"] = follow ? lastPostID : NSNull()

        // Add/remove signed-in user to the list of followers.
        updateData["followers/\(self.profile.userID)/\(self.uid)"] = follow ? true : NSNull()
        self.ref.updateChildValues(updateData) { error, _ in
          if let error = error {
            print(error.localizedDescription)
          }
        }
      }
    })
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

  @IBAction func tapDeleteAccount() {
    let alertController = MDCAlertController.init(title: "Delete Account?", message: nil)
    let cancelAction = MDCAlertAction(title:"Cancel") { _ in print("Cancel") }
    let deleteAction = MDCAlertAction(title:"Delete") { _ in
      Auth.auth().currentUser?.delete(completion: { error in
        if let error = error {
          let errorController = MDCAlertController.init(title: "Deletion requires recent authentication", message: "Log in again before retrying.")
          let okAction = MDCAlertAction(title:"OK") { _ in self.feedViewController?.didTapSignOut(()) }
          errorController.addAction(okAction)
          self.present(errorController, animated:true, completion:nil)
          return
        }
        MDCSnackbarManager.show(MDCSnackbarMessage(text: "Account deleted."))
        self.feedViewController?.didTapSignOut(())
      })
    }

    alertController.addAction(deleteAction)
    alertController.addAction(cancelAction)
    present(alertController, animated:true, completion:nil)
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
