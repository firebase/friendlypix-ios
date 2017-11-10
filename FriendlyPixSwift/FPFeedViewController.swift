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
import GoogleSignIn
import MaterialComponents

class FPFeedViewController: MDCCollectionViewController, FPCardCollectionViewCellDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, InviteDelegate, GIDSignInDelegate, GIDSignInUIDelegate {

  let uid = Auth.auth().currentUser!.uid

  var ref: DatabaseReference!
  var postsRef: DatabaseReference!
  var commentsRef: DatabaseReference!
  var likesRef: DatabaseReference!
  var query: DatabaseReference!
  var posts = [FPPost]()
  var loadingPostCount = 0
  var sizingNibNew: FPCardCollectionViewCell!
  let bottomBarView = MDCBottomAppBarView()
  var alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
  var showFeed = false
  let homeButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_home"), style: .plain, target: self, action: #selector(homeAction))
  let searchButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_search"), style: .plain, target: self, action: #selector(searchAction))
  let feedButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_trending_up"), style: .plain, target: self, action: #selector(feedAction))
  let blue = MDCPalette.blue.tint600

  override func awakeFromNib() {

    let titleLabel = UILabel()
    titleLabel.text = "Friendly Pix"
    titleLabel.textColor = UIColor.white
    titleLabel.font = UIFont(name: "Amaranth", size: 24)
    titleLabel.sizeToFit()
    navigationItem.leftBarButtonItems?.append(UIBarButtonItem(customView: titleLabel))

    bottomBarView.autoresizingMask = [ .flexibleWidth, .flexibleTopMargin ]
    view.addSubview(bottomBarView)

    // Add touch handler to the floating button.
    bottomBarView.floatingButton.addTarget(self,
                                           action: #selector(didTapFloatingButton),
                                           for: .touchUpInside)

    // Set the image on the floating button.
    bottomBarView.floatingButton.setImage(#imageLiteral(resourceName: "ic_photo_camera"), for: .normal)
    bottomBarView.floatingButton.setImage(#imageLiteral(resourceName: "ic_photo_camera_white"), for: .highlighted)

    // Set the position of the floating button.
    bottomBarView.floatingButtonPosition = .center

    // Theme the floating button.
    let colorScheme = MDCBasicColorScheme(primaryColor: MDCPalette.amber.tint400)
    MDCButtonColorThemer.apply(colorScheme, to: bottomBarView.floatingButton)

    // Configure the navigation buttons to be shown on the bottom app bar.

    homeButton.tintColor = blue

    let button = UIButton(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
    button.addTarget(self, action: #selector(clickUser), for: .touchUpInside)
    if let photoURL = Auth.auth().currentUser?.photoURL {
      UIImage.circleButton(with: photoURL, to: button)
    }

    let profileButton = UIBarButtonItem(customView: button)
    profileButton.imageInsets = UIEdgeInsetsMake(0, 0, 0, 0)

    navigationController?.setToolbarHidden(true, animated: false)
    
    bottomBarView.leadingBarButtonItems = [ homeButton, feedButton ]
    bottomBarView.trailingBarButtonItems = [ profileButton, searchButton ]

    let button0 = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alert.addAction(button0)

    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      let button1 = UIAlertAction(title: "Take photo", style: .default) { _ in
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .camera
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: nil)
      }
      alert.addAction(button1)
    }
    if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) ||
      UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
      let button2 = UIAlertAction(title: "Choose Existing", style: .default) { _ in
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType =
          UIImagePickerController.isSourceTypeAvailable(.photoLibrary) ? .photoLibrary : .savedPhotosAlbum
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        self.present(imagePickerController, animated: true, completion: nil)
      }
      alert.addAction(button2)
    }
  }

  override func viewWillLayoutSubviews() {
    let size = bottomBarView.sizeThatFits(view.bounds.size)
    let bottomBarViewFrame = CGRect(x: 0,
                                    y: view.bounds.size.height - size.height,
                                    width: size.width,
                                    height: size.height)
    bottomBarView.frame = bottomBarViewFrame
  }

  @objc private func didTapFloatingButton() {
    present(alert, animated: true, completion: nil)
  }

  @objc private func homeAction() {
    homeButton.tintColor = blue
    feedButton.tintColor = nil
    showFeed = false
    posts = [FPPost]()
    loadingPostCount = 0
    collectionView?.reloadData()
    loadData()
  }

  @objc private func feedAction() {
    homeButton.tintColor = nil
    feedButton.tintColor = blue
    showFeed = true
    posts = [FPPost]()
    loadingPostCount = 0
    collectionView?.reloadData()
    loadData()
  }

  @objc private func searchAction() {
    performSegue(withIdentifier: "search", sender: self)
  }

  @objc private func clickUser() {
    showProfile(FPUser.currentUser())
  }

  // MARK: - UIImagePickerDelegate
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
    dismiss(animated: false, completion: nil)
    performSegue(withIdentifier: "upload", sender: info)
  }

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
    self.styler.cellLayoutType = .grid
    self.styler.gridColumnCount = 1
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

  func getHomeFeedPosts() {
    loadFeed(nil)
  }

  func loadData() {
    if showFeed {
      query = postsRef
      loadFeed(nil)
    } else {
      query = ref.child("feed").child(uid)
      // Make sure the home feed is updated with followed users's new posts.
      // Only after the feed creation is complete, start fetching the posts.
      updateHomeFeeds()
    }
  }

  func loadItem(_ item: DataSnapshot) {
    if showFeed {
      loadPost(item)
    } else {
      ref.child("posts/" + (item.key)).observe(.value) { postSnapshot in
        self.loadPost(postSnapshot)
      }
    }
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
    guard let identifier = segue.identifier else { return }
    switch identifier {
    case "account":
      if let accountViewController = segue.destination as? FPAccountViewController, let profile = sender as? FPUser {
        accountViewController.profile = profile
      }
    case "comment":
      if let commentViewController = segue.destination as? FPCommentViewController, let post = sender as? FPPost {
       commentViewController.post = post
      }
    case "upload":
      let viewController = segue.destination as? FPUploadViewController
      if let sender = sender as? [String: Any] {
        if let image = sender[UIImagePickerControllerEditedImage] as? UIImage {
          viewController?.image = image
        } else if let image = sender[UIImagePickerControllerOriginalImage] as? UIImage {
          viewController?.image = image
        }
        viewController?.referenceURL = sender[UIImagePickerControllerReferenceURL] as? URL
      }
    default:
      print("Unexpected segue")
    }
  }

  /**
   * Keeps the home feed populated with latest followed users' posts live.
   */
  func startHomeFeedLiveUpdaters() {
    // Make sure we listen on each followed people's posts.
    let followingRef = ref.child("people").child(uid).child("following")
    followingRef.observe(.childAdded, with: { followingSnapshot in
      // Start listening the followed user's posts to populate the home feed.
      let followedUid = followingSnapshot.key
      var followedUserPostsRef: DatabaseQuery = self.ref.child("people").child(followedUid).child("posts")
      if followingSnapshot.exists() && (followingSnapshot.value is String) {
        followedUserPostsRef = followedUserPostsRef.queryOrderedByKey().queryStarting(atValue: followingSnapshot.value)
      }
      followedUserPostsRef.observe(.childAdded, with: { postSnapshot in
        if postSnapshot.key != followingSnapshot.key {
          let updates = ["/feed/\(self.uid)/\(postSnapshot.key)": true,
                         "/people/\(self.uid)/following/\(followedUid)": postSnapshot.key] as [String: Any]
          self.ref.updateChildValues(updates)
        }
      })
    })
    // Stop listening to users we unfollow.
    followingRef.observe(.childRemoved, with: { snapshot in
      // Stop listening the followed user's posts to populate the home feed.
      let followedUserId: String = snapshot.key
      self.ref.child("people").child(followedUserId).child("posts").removeAllObservers()
    })
  }

  /**
   * Updates the home feed with new followed users' posts and returns a promise once that's done.
   */
  func updateHomeFeeds() {
    // Make sure we listen on each followed people's posts.
    let followingRef = ref.child("people").child(uid).child("following")
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
        followedUserPostsRef = self.ref.child("people").child(followedUid).child("posts")
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
            self.ref.updateChildValues(updates)
          }
          // Add new posts from followers live.
          self.startHomeFeedLiveUpdaters()
          // Get home feed posts
          self.getHomeFeedPosts()
        })
      }
    })
  }
  @IBAction func inviteTapped(_ sender: Any) {
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    GIDSignIn.sharedInstance().uiDelegate = self
    GIDSignIn.sharedInstance().delegate = self
    GIDSignIn.sharedInstance().signInSilently()
  }
  func inviteFinished(withInvitations invitationIds: [String], error: Error?) {
    if let error = error {
      print("Failed: \(error.localizedDescription)")
    } else {
      print("\(invitationIds.count) invites sent")
    }
  }
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
    switch error {
      case .some(let error as NSError) where error.code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue:
        GIDSignIn.sharedInstance().signIn()
      case .some(let error):
        print("Login error: \(error.localizedDescription)")
      case .none:
        if let invite = Invites.inviteDialog() {
          invite.setInviteDelegate(self)
    
          // NOTE: You must have the App Store ID set in your developer console project
          // in order for invitations to successfully be sent.
          // A message hint for the dialog. Note this manifests differently depending on the
          // received invitation type. For example, in an email invite this appears as the subject.
          invite.setMessage("Try this out!\n -\(Auth.auth().currentUser!.displayName ?? "")")
          // Title for the dialog, this is what the user sees before sending the invites.
          invite.setTitle("Invites Example")
          invite.setDeepLink("app_url")
          invite.setCallToActionText("Install!")
          invite.open()
      }
    }
  }
}

extension MDCCollectionViewController {
  var feedViewController: FPFeedViewController? {
    return navigationController?.viewControllers[0] as? FPFeedViewController
  }
}
