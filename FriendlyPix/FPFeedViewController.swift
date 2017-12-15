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
import ImagePicker
import Lightbox
import MaterialComponents

class FPFeedViewController: MDCCollectionViewController, FPCardCollectionViewCellDelegate {

  lazy var uid = Auth.auth().currentUser!.uid

  lazy var ref = Database.database().reference()
  lazy var followingRef = self.ref.child("people").child(self.uid).child("following")
  lazy var postsRef = self.ref.child("posts")
  lazy var commentsRef = self.ref.child("comments")
  lazy var likesRef = self.ref.child("likes")

  var query: DatabaseReference!
  var posts = [FPPost]()
  var loadingPostCount = 0
  var nextEntry: String?
  var sizingNibNew: FPCardCollectionViewCell!
  let bottomBarView = MDCBottomAppBarView()
  var alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
  var showFeed = false
  let homeButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_home"), style: .plain, target: self, action: #selector(homeAction))
  let searchButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_search"), style: .plain, target: self, action: #selector(searchAction))
  let feedButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_trending_up"), style: .plain, target: self, action: #selector(feedAction))
  let blue = MDCPalette.blue.tint600
  var observers = [DatabaseQuery]()

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let lightboxImages = posts.map {
      return LightboxImage(imageURL: $0.fullURL, text: "\($0.author.fullname): \($0.text)")
    }

    let lightbox = LightboxController(images: lightboxImages, startIndex: indexPath.item)
    lightbox.dynamicBackground = true
    self.present(lightbox, animated: true, completion: nil)
  }

  override func awakeFromNib() {
    super.awakeFromNib()

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

    let profileButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_insert_photo_white_36pt"), style: .plain, target: self, action: #selector(clickUser))
    //let spacer = UIBarButtonItem(customView: UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10)))

    navigationController?.setToolbarHidden(true, animated: false)
    homeButton.tintColor = blue
    feedButton.tintColor = .gray
    searchButton.tintColor = .gray

    bottomBarView.leadingBarButtonItems = [ homeButton, feedButton ]
    bottomBarView.trailingBarButtonItems = [ profileButton, searchButton ]
    self.present(FPSignInViewController(), animated: false, completion: nil)
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

  override func viewWillLayoutSubviews() {
    let size = bottomBarView.sizeThatFits(view.bounds.size)
    let bottomBarViewFrame = CGRect(x: 0,
                                    y: view.bounds.size.height - size.height,
                                    width: size.width,
                                    height: size.height)
    bottomBarView.frame = bottomBarViewFrame
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    cleanCollectionView()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if let photoURL = Auth.auth().currentUser?.photoURL {
      UIImage.circleButton(with: photoURL, to: bottomBarView.trailingBarButtonItems![0])
    }

    loadData()
  }

  override func viewWillDisappear(_ animated: Bool) {
    loadingPostCount = 0
    posts = [FPPost]()
    nextEntry = nil
    super.viewWillDisappear(animated)
    followingRef.removeAllObservers()
    postsRef.removeAllObservers()
    for observer in observers {
      observer.removeAllObservers()
    }
  }

  @objc private func homeAction() {
    bottomBarView.subviews[2].subviews[1].subviews[0].tintColor = blue
    bottomBarView.subviews[2].subviews[1].subviews[1].tintColor = .gray
    showFeed = false
    postsRef.removeAllObservers()
    for observer in observers {
      observer.removeAllObservers()
    }
    observers = [DatabaseQuery]()
    posts = [FPPost]()
    loadingPostCount = 0
    nextEntry = nil
    cleanCollectionView()
    loadData()
  }

  @objc private func feedAction() {
    bottomBarView.subviews[2].subviews[1].subviews[0].tintColor = .gray
    bottomBarView.subviews[2].subviews[1].subviews[1].tintColor = blue
    followingRef.removeAllObservers()
    postsRef.removeAllObservers()
    for observer in observers {
      observer.removeAllObservers()
    }
    observers = [DatabaseQuery]()
    showFeed = true
    posts = [FPPost]()
    loadingPostCount = 0
    nextEntry = nil
    cleanCollectionView()
    loadData()
  }

  @objc private func searchAction() {
    performSegue(withIdentifier: "search", sender: self)
  }

  @objc private func clickUser() {
    showProfile(FPUser.currentUser())
  }

  func getHomeFeedPosts() {
    loadFeed()
  }

  func loadData() {
    if showFeed {
      query = postsRef
      loadFeed()
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
      ref.child("posts/" + (item.key)).observeSingleEvent(of: .value) { postSnapshot in
        self.loadPost(postSnapshot)
      }
    }
  }

  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
    if indexPath.item == (loadingPostCount - 1) {
      loadFeed()
    }
  }

  func loadFeed() {
    var query = self.query?.queryOrderedByKey()
    if let queryEnding = nextEntry {
      query = query?.queryEnding(atValue: queryEnding)
    }
    loadingPostCount += 5
    query?.queryLimited(toLast: 6).observeSingleEvent(of: .value, with: { snapshot in
      if let reversed = snapshot.children.allObjects as? [DataSnapshot], !reversed.isEmpty {
        self.nextEntry = reversed[0].key
        self.collectionView?.performBatchUpdates({
          for index in stride(from: reversed.count - 1, through: 1, by: -1) {
            self.loadItem(reversed[index])
          }
        }, completion: nil)
      }
    })
    postsRef.observe(.childRemoved, with: { postSnapshot in
      var index = 0
      for post in self.posts {
        if post.postID == postSnapshot.key {
          self.posts.remove(at: index)
          self.collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
          break
        }
        index += 1
      }
    })
  }

  func loadPost(_ postSnapshot: DataSnapshot) {
    let postId = postSnapshot.key
    commentsRef.child(postId).observeSingleEvent(of: .value, with: { commentsSnapshot in
      var commentsArray = [FPComment]()
      let enumerator = commentsSnapshot.children
      while let commentSnapshot = enumerator.nextObject() as? DataSnapshot {
        let comment = FPComment(snapshot: commentSnapshot)
        commentsArray.append(comment)
      }
      let likesQuery = self.likesRef.child(postId)
      likesQuery.observeSingleEvent(of: .value, with: { snapshot in
        let likes = snapshot.value as? [String: Any]
        let post = FPPost(snapshot: postSnapshot, andComments: commentsArray, andLikes: likes)
        self.commentsRef.child(postId)
        self.posts.append(post)
        let last = self.posts.count - 1
        let lastIndex = [IndexPath(item: last, section: 0)]
        var commentQuery: DatabaseQuery = self.commentsRef.child(postId)
        let lastCommentId = commentsArray.last?.commentID
        if let lastCommentId = lastCommentId {
          commentQuery = commentQuery.queryOrderedByKey().queryStarting(atValue: lastCommentId)
        }
        commentQuery.observe(.childAdded, with: { dataSnaphot in
          if dataSnaphot.key != lastCommentId {
            post.comments.append(FPComment(snapshot: dataSnaphot))
            self.collectionView?.reloadItems(at: lastIndex)
          }
        })
        self.observers.append(commentQuery)
        likesQuery.observe(.value, with: {
          let count = Int($0.childrenCount)
          if post.likeCount != count {
            post.likeCount = count
            post.isLiked = $0.hasChild(self.uid)
            self.collectionView?.reloadItems(at: lastIndex)
          }
        })
        self.observers.append(likesQuery)
        self.collectionView?.insertItems(at: lastIndex)
      })
    })
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
      postLike.removeValue { error, _ in
        if let error = error {
          print(error.localizedDescription)
          return
        }
      }
    } else {
      postLike.setValue(ServerValue.timestamp()) { error, _ in
        if let error = error {
          print(error.localizedDescription)
          return
        }
      }
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
      if let viewController = segue.destination as? FPUploadViewController, let image = sender as? UIImage {
        viewController.image = image
      }
    default:
      break
    }
  }

  /**
   * Keeps the home feed populated with latest followed users' posts live.
   */
  func startHomeFeedLiveUpdaters() {
    // Make sure we listen on each followed people's posts.
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
      self.observers.append(followedUserPostsRef)
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
}

extension FPFeedViewController: ImagePickerDelegate {
  func didTapFloatingButton() {
    var config = Configuration()
    config.recordLocation = false
    config.allowMultiplePhotoSelection = false

    let imagePicker = ImagePickerController(configuration: config)
    imagePicker.delegate = self

    present(imagePicker, animated: true, completion: nil)
  }

  func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
    imagePicker.dismiss(animated: true, completion: nil)
  }

  func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
    guard images.count > 0 else { return }

    let lightboxImages = images.map {
      return LightboxImage(image: $0)
    }

    let lightbox = LightboxController(images: lightboxImages, startIndex: 0)
    lightbox.dynamicBackground = true
    imagePicker.present(lightbox, animated: true, completion: nil)
  }

  func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
    imagePicker.dismiss(animated: true, completion: nil)
    guard images.count > 0 else { return }
    self.performSegue(withIdentifier: "upload", sender: images[0])
  }
}

extension FPFeedViewController: InviteDelegate, GIDSignInDelegate, GIDSignInUIDelegate {
  @IBAction func inviteTapped(_ sender: Any) {
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    GIDSignIn.sharedInstance().scopes = ["https://www.googleapis.com/auth/userinfo.email",
                                         "https://www.googleapis.com/auth/userinfo.profile"]
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
        //let x 
        //invite.setCustomImage(#imageLiteral(resourceName: "ic_insert_photo_white").imageAsset.)
        invite.setTitle("Friendly Pix")
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

  internal func cleanCollectionView() {
    if collectionView!.numberOfItems(inSection: 0) > 0 {
      collectionView!.reloadSections([0])
    }
  }
}
