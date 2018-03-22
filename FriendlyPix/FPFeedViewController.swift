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
import FirebaseAuthUI
import GoogleSignIn
import ImagePicker
import Lightbox
import MaterialComponents

class FPFeedViewController: MDCCollectionViewController, FPCardCollectionViewCellDelegate {
  var uid: String!
  var followingRef: DatabaseReference?

  lazy var ref = Database.database().reference()
  lazy var postsRef = self.ref.child("posts")
  lazy var commentsRef = self.ref.child("comments")
  lazy var likesRef = self.ref.child("likes")

  var floatingButtonOffset: CGFloat = 0.0
  var spinner: UIView?
  static let postsPerLoad: Int = 3
  static let postsLimit: UInt = 4
  var lightboxCurrentPage: Int?

  let emptyHomeLabel: UILabel = {
    let messageLabel = UILabel()
    messageLabel.text = "This feed will be populated as you follow more people."
    messageLabel.textColor = UIColor.black
    messageLabel.numberOfLines = 0
    messageLabel.textAlignment = .center
    messageLabel.font = UIFont.preferredFont(forTextStyle: .title3)
    messageLabel.sizeToFit()
    return messageLabel
  }()

  var query: DatabaseReference!
  var posts = [FPPost]()
  var loadingPostCount = 0
  var nextEntry: String?
  var sizingCell: FPCardCollectionViewCell!
  let bottomBarView = MDCBottomAppBarView()
  var showFeed = false
  let homeButton = { () -> UIBarButtonItem in
    let button = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_home"), style: .plain, target: self, action: #selector(homeAction))
    button.accessibilityLabel = "Home"
    return button
  }()
  let feedButton = { () -> UIBarButtonItem in
    let button = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_trending_up"), style: .plain, target: self, action: #selector(feedAction))
    button.accessibilityLabel = "Feed"
    return button
  }()
  let blue = MDCPalette.blue.tint600
  var observers = [DatabaseQuery]()
  var newPost = false
  var followChanged = false
  var isFirstOpen = true

  func showLightbox(_ index: Int) {
    let lightboxImages = posts.map {
      return LightboxImage(imageURL: $0.fullURL, text: "\($0.author.fullname): \($0.text)")
    }

    LightboxConfig.InfoLabel.textAttributes[.font] = UIFont.preferredFont(forTextStyle: .body)
    let lightbox = LightboxController(images: lightboxImages, startIndex: index)
    lightbox.dynamicBackground = true
    lightbox.dismissalDelegate = self

    self.present(lightbox, animated: true, completion: nil)
  }

  override func awakeFromNib() {
    super.awakeFromNib()

    let titleLabel = UILabel()
    titleLabel.text = "Friendly Pix"
    titleLabel.textColor = UIColor.white
    titleLabel.font = UIFont(name: "Amaranth", size: 24)
    titleLabel.sizeToFit()
    navigationController?.navigationBar.titleTextAttributes![.font] = UIFont.preferredFont(forTextStyle: .title3)
    navigationItem.leftBarButtonItems = [UIBarButtonItem.init(customView: UIImageView.init(image: #imageLiteral(resourceName: "image_logo"))), UIBarButtonItem(customView: titleLabel)]

    bottomBarView.autoresizingMask = [ .flexibleWidth, .flexibleTopMargin ]
    view.addSubview(bottomBarView)

    // Add touch handler to the floating button.
    bottomBarView.floatingButton.addTarget(self,
                                           action: #selector(didTapFloatingButton),
                                           for: .touchUpInside)

    // Set the image on the floating button.
    bottomBarView.floatingButton.setImage(#imageLiteral(resourceName: "ic_photo_camera"), for: .normal)
    bottomBarView.floatingButton.setImage(#imageLiteral(resourceName: "ic_photo_camera_white"), for: .highlighted)
    bottomBarView.floatingButton.accessibilityLabel = "Open camera"

    // Set the position of the floating button.
    bottomBarView.floatingButtonPosition = .center

    // Theme the floating button.
    let colorScheme = MDCBasicColorScheme(primaryColor: MDCPalette.amber.tint400)
    MDCButtonColorThemer.apply(colorScheme, to: bottomBarView.floatingButton)

    // Configure the navigation buttons to be shown on the bottom app bar.

    navigationController?.setToolbarHidden(true, animated: false)
    homeButton.tintColor = blue
    feedButton.tintColor = .gray


    bottomBarView.leadingBarButtonItems = [ homeButton, feedButton ]
    bottomBarView.subviews[2].subviews[1].subviews[0].accessibilityTraits = UIAccessibilityTraitSelected
    bottomBarView.subviews[2].subviews[1].accessibilityTraits = UIAccessibilityTraitTabBar
    let inviteButton = UIBarButtonItem.init(image: #imageLiteral(resourceName: "ic_person_add"), style: .plain, target: self, action: #selector(inviteTapped))
    inviteButton.tintColor = .gray
    inviteButton.accessibilityLabel = "invite friends"
    bottomBarView.trailingBarButtonItems = [ inviteButton ]
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let nib = UINib(nibName: "FPCardCollectionViewCell", bundle: nil)

    guard let collectionView = collectionView else {
      return
    }
    collectionView.register(nib, forCellWithReuseIdentifier: "cell")
    sizingCell = Bundle.main.loadNibNamed("FPCardCollectionViewCell", owner: self, options: nil)?[0]
      as? FPCardCollectionViewCell

    self.styler.cellStyle = .card
    self.styler.cellLayoutType = .grid
    self.styler.gridColumnCount = 1
    let insets = self.collectionView(collectionView,
                                     layout: collectionViewLayout,
                                     insetForSectionAt: 0)
    let cellFrame = CGRect(x: 0, y: 0, width: collectionView.bounds.width - insets.left - insets.right,
                           height: collectionView.bounds.height)
    sizingCell.frame = cellFrame

    if #available(iOS 10.0, *) {
      let refreshControl = UIRefreshControl()
      refreshControl.addTarget(self,
                               action: #selector(refreshOptions(sender:)),
                               for: .valueChanged)
      collectionView.refreshControl = refreshControl
    }
  }

  @objc private func refreshOptions(sender: UIRefreshControl) {
    reloadFeed()
    sender.endRefreshing()
  }

  private func reloadFeed() {
    followingRef?.removeAllObservers()
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

  override func viewWillLayoutSubviews() {
    let size = bottomBarView.sizeThatFits(view.bounds.size)
    let bottomBarViewFrame = CGRect(x: 0,
                                    y: view.bounds.size.height - size.height,
                                    width: size.width,
                                    height: size.height)
    bottomBarView.frame = bottomBarViewFrame
    MDCSnackbarManager.setBottomOffset(bottomBarView.frame.height)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if let currentUser = Auth.auth().currentUser  {
      self.uid = currentUser.uid
      self.followingRef = ref.child("people/\(uid)/following")
    } else {
      let authViewController = FUIAuth.defaultAuthUI()?.authViewController()
      authViewController?.navigationBar.isHidden = true
      self.present(authViewController!, animated: true, completion: nil)
      return
    }
    MDCSnackbarManager.setBottomOffset(bottomBarView.frame.height)
    if let photoURL = Auth.auth().currentUser?.photoURL, let item = navigationItem.rightBarButtonItems?[0] {
      UIImage.circleButton(with: photoURL, to: item)
      item.accessibilityLabel = ""
      item.accessibilityHint = "Double-tap to open your profile."
    }
    navigationItem.rightBarButtonItems?[1].accessibilityLabel = "Search people"
    if newPost {
      reloadFeed()
      newPost = false
      return
    }
    if !showFeed && followChanged {
      reloadFeed()
      followChanged = false
      return
    }
    loadData()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    followingRef?.removeAllObservers()
    postsRef.removeAllObservers()
    for observer in observers {
      observer.removeAllObservers()
    }
    observers = [DatabaseQuery]()
    MDCSnackbarManager.setBottomOffset(0)
    if let spinner = spinner {
      removeSpinner(spinner)
    }
  }

  @objc private func homeAction() {
    bottomBarView.subviews[2].subviews[1].subviews[0].tintColor = blue
    bottomBarView.subviews[2].subviews[1].subviews[0].accessibilityTraits = UIAccessibilityTraitSelected
    bottomBarView.subviews[2].subviews[1].subviews[1].tintColor = .gray
    bottomBarView.subviews[2].subviews[1].subviews[1].accessibilityTraits = UIAccessibilityTraitNone
    showFeed = false
    reloadFeed()
  }

  @objc private func feedAction() {
    bottomBarView.subviews[2].subviews[1].subviews[0].tintColor = .gray
    bottomBarView.subviews[2].subviews[1].subviews[0].accessibilityTraits = UIAccessibilityTraitNone
    bottomBarView.subviews[2].subviews[1].subviews[1].tintColor = blue
    bottomBarView.subviews[2].subviews[1].subviews[1].accessibilityTraits = UIAccessibilityTraitSelected
    showFeed = true
    reloadFeed()
  }

  @IBAction func didTapSearch(_ sender: Any) {
    performSegue(withIdentifier: "search", sender: self)
  }

  @IBAction func didTapProfile(_ sender: Any) {
    showProfile(FPUser.currentUser())
  }

  func getHomeFeedPosts() {
    loadFeed()
    listenDeletes()
  }

  func loadData() {
    spinner = displaySpinner()
    if showFeed {
      query = postsRef
      loadFeed()
      listenDeletes()
    } else {
      query = ref.child("feed").child(uid!)
      // Make sure the home feed is updated with followed users's new posts.
      // Only after the feed creation is complete, start fetching the posts.
      updateHomeFeeds()
    }
  }

  func listenDeletes() {
    postsRef.observe(.childRemoved, with: { postSnapshot in
      if let index = self.posts.index(where: {$0.postID == postSnapshot.key}) {
        self.posts.remove(at: index)
        self.loadingPostCount -= 1
        self.collectionView?.deleteItems(at: [IndexPath(item: index, section: 0)])
      }
    })
  }

  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
    if indexPath.item == (loadingPostCount - 1) {
      loadFeed()
    }
  }

  func loadFeed() {
    if observers.isEmpty && !posts.isEmpty {
      if let spinner = spinner {
        removeSpinner(spinner)
      }
      self.collectionView?.performBatchUpdates({
        var index = posts.count - 1
        for post in posts.reversed() {
          let current = index
          postsRef.child(post.postID).observeSingleEvent(of: .value, with: {
            let indexPath = [IndexPath(item: current, section: 0)]
            if $0.exists() {
              self.updatePost(post, postSnapshot: $0, at: indexPath)
              self.listenPost(post, at: indexPath)
            } else {
              self.posts.remove(at: current)
              self.loadingPostCount -= 1
              self.collectionView?.deleteItems(at: indexPath)
              if self.posts.isEmpty {
                self.collectionView?.backgroundView = self.emptyHomeLabel
              }
            }
          })
          index -= 1
        }
      }, completion: nil)
    } else {
      var query = self.query?.queryOrderedByKey()
      if let queryEnding = nextEntry {
        query = query?.queryEnding(atValue: queryEnding)
      }
      loadingPostCount = posts.count + FPFeedViewController.postsPerLoad
      query?.queryLimited(toLast: FPFeedViewController.postsLimit).observeSingleEvent(of: .value, with: { snapshot in
        if let spinner = self.spinner {
          self.removeSpinner(spinner)
        }
        if let reversed = snapshot.children.allObjects as? [DataSnapshot], !reversed.isEmpty {
          self.collectionView?.backgroundView = nil
          self.nextEntry = reversed[0].key
          var results = [Int: DataSnapshot]()
          let myGroup = DispatchGroup()
          let extraElement = reversed.count > FPFeedViewController.postsPerLoad ? 1 : 0
          self.collectionView?.performBatchUpdates({
            for index in stride(from: reversed.count - 1, through: extraElement, by: -1) {
              let item = reversed[index]
              if self.showFeed {
                self.loadPost(item)
              } else {
                myGroup.enter()
                let current = reversed.count - 1 - index
                self.postsRef.child(item.key).observeSingleEvent(of: .value) {
                  results[current] = $0
                  myGroup.leave()
                }
              }
            }
            myGroup.notify(queue: .main) {
              if !self.showFeed {
                for index in 0..<(reversed.count - extraElement) {
                  if let spinner = self.spinner {
                    self.removeSpinner(spinner)
                  }
                  self.loadPost(results[index]!)
                }
              }
            }
          }, completion: nil)
        } else if self.posts.isEmpty && !self.showFeed {
          if self.isFirstOpen {
            self.feedAction()
            self.isFirstOpen = false
          } else {
            self.collectionView?.backgroundView = self.emptyHomeLabel
          }
        }
      })
    }
  }

  func listenPost(_ post: FPPost, at: [IndexPath]) {
    let commentQuery: DatabaseQuery = self.commentsRef.child(post.postID)
    var lastCommentQuery = commentQuery
    let lastCommentId = post.comments.last?.commentID
    if let lastCommentId = lastCommentId {
      lastCommentQuery = commentQuery.queryOrderedByKey().queryStarting(atValue: lastCommentId)
    }
    lastCommentQuery.observe(.childAdded, with: { dataSnaphot in
      if dataSnaphot.key != lastCommentId {
        post.comments.append(FPComment(snapshot: dataSnaphot))
        self.collectionView?.reloadItems(at: at)
        self.collectionViewLayout.invalidateLayout()
      }
    })
    commentQuery.observe(.childChanged, with: { dataSnaphot in
      if let index = post.comments.index(where: {$0.commentID == dataSnaphot.key}) {
        post.comments[index] = .init(snapshot: dataSnaphot)
        self.collectionView?.reloadItems(at: at)
        self.collectionViewLayout.invalidateLayout()
      }
    })
    commentQuery.observe(.childRemoved, with: { dataSnaphot in
      if let index = post.comments.index(where: {$0.commentID == dataSnaphot.key}) {
        post.comments.remove(at: index)
        self.collectionView?.reloadItems(at: at)
        self.collectionViewLayout.invalidateLayout()
      }
    })
    self.observers.append(commentQuery)
    self.observers.append(lastCommentQuery)
    let likesQuery = self.likesRef.child(post.postID)
    likesQuery.observe(.value, with: {
      let count = Int($0.childrenCount)
      if post.likeCount != count || post.isLiked != $0.hasChild(self.uid){
        post.likeCount = count
        post.isLiked = $0.hasChild(self.uid)
        self.collectionView?.reloadItems(at: at)
      }
    })
    self.observers.append(likesQuery)
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
      self.likesRef.child(postId).observeSingleEvent(of: .value, with: { snapshot in
        let likes = snapshot.value as? [String: Any]
        let post = FPPost(snapshot: postSnapshot, andComments: commentsArray, andLikes: likes)
        self.posts.append(post)
        let last = self.posts.count - 1
        let lastIndex = [IndexPath(item: last, section: 0)]
        self.listenPost(post, at: lastIndex)
        self.collectionView?.insertItems(at: lastIndex)
      })
    })
  }

  func updatePost(_ post: FPPost, postSnapshot: DataSnapshot, at: [IndexPath]) {
    let postId = postSnapshot.key
    commentsRef.child(postId).observeSingleEvent(of: .value, with: { commentsSnapshot in
      var commentsArray = [FPComment]()
      let enumerator = commentsSnapshot.children
      while let commentSnapshot = enumerator.nextObject() as? DataSnapshot {
        let comment = FPComment(snapshot: commentSnapshot)
        commentsArray.append(comment)
      }
      if post.comments != commentsArray {
        post.comments = commentsArray
        self.collectionView?.reloadItems(at: at)
        self.collectionViewLayout.invalidateLayout()
      }
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
      cell.populateContent(post: post, index: indexPath.item, isDryRun: false)
      cell.delegate = self
    }
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
    let post = posts[indexPath.item]
    sizingCell.populateContent(post: post, index: indexPath.item, isDryRun: true)

    sizingCell.setNeedsUpdateConstraints()
    sizingCell.updateConstraintsIfNeeded()
    sizingCell.contentView.setNeedsLayout()
    sizingCell.contentView.layoutIfNeeded()

    var fittingSize = UILayoutFittingCompressedSize
    fittingSize.width = sizingCell.frame.width

    let size = sizingCell.contentView.systemLayoutSizeFitting(fittingSize)
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

  func deletePost(_ post: FPPost, completion: (() -> Swift.Void)? = nil) {
    let alertController = MDCAlertController.init(title: "Delete Post?", message: nil)
    let cancelAction = MDCAlertAction(title:"Cancel") { _ in print("Cancel") }
    let deleteAction = MDCAlertAction(title:"Delete") { _ in
      let postID = post.postID
      let update = [ "people/\(self.uid)/posts/\(postID)": NSNull(),
                     "comments/\(postID)": NSNull(),
                     "likes/\(postID)": NSNull(),
                     "posts/\(postID)": NSNull(),
                     "feed/\(self.uid)/\(postID)": NSNull()]
      self.ref.updateChildValues(update) { error, reference in
        if let error = error {
          print(error.localizedDescription)
          return
        }
        if let completion = completion {
          completion()
        }
      }
      let storage = Storage.storage()
      storage.reference(forURL: post.fullURL.absoluteString).delete()
      storage.reference(forURL: post.thumbURL.absoluteString).delete()
    }

    alertController.addAction(deleteAction)
    alertController.addAction(cancelAction)
    present(alertController, animated:true, completion:nil)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    isFirstOpen = false
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
        newPost = true
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
    followingRef?.observe(.childAdded, with: { followingSnapshot in
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
    followingRef?.observe(.childRemoved, with: { snapshot in
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
    followingRef?.observeSingleEvent(of: .value, with: { followingSnapshot in
      // Start listening the followed user's posts to populate the home feed.
      guard let following = followingSnapshot.value as? [String: Any] else {
        self.startHomeFeedLiveUpdaters()
        // Get home feed posts
        self.getHomeFeedPosts()
        return
      }
      var followedUserPostsRef: DatabaseQuery!
      let myGroup = DispatchGroup()
      for (followedUid, lastSyncedPostId) in following {
        myGroup.enter()
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
            self.ref.updateChildValues(updates, withCompletionBlock: { error, reference in
              myGroup.leave()
            })
          } else {
            myGroup.leave()
          }
        })
      }
      myGroup.notify(queue: .main) {
        // Add new posts from followers live.
        self.startHomeFeedLiveUpdaters()
        // Get home feed posts
        self.getHomeFeedPosts()
      }
    })
  }
}

extension FPFeedViewController: LightboxControllerDismissalDelegate{
  func lightboxControllerWillDismiss(_ controller: LightboxController) {
    self.collectionView?.scrollToItem(at: IndexPath.init(item: controller.currentPage, section: 0), at: .top, animated: false)
  }
}

extension FPFeedViewController: ImagePickerDelegate {
  @objc func didTapFloatingButton() {
    var config = Configuration()
    config.recordLocation = false
    config.allowMultiplePhotoSelection = false
    config.showsImageCountLabel = false

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
  @objc func inviteTapped() {
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    GIDSignIn.sharedInstance().scopes = ["https://www.googleapis.com/auth/userinfo.email",
                                         "https://www.googleapis.com/auth/userinfo.profile"]
    GIDSignIn.sharedInstance().uiDelegate = self
    GIDSignIn.sharedInstance().delegate = self
    GIDSignIn.sharedInstance().signInSilently()
  }

  func inviteFinished(withInvitations invitationIds: [String], error: Error?) {
    switch error {
    case .some(let error as NSError) where error.code == -1009:
      MDCSnackbarManager.show(MDCSnackbarMessage(text: error.localizedDescription))
    case .some(let error):
      print("Failed: \(error.localizedDescription)")
    case .none:
      print("\(invitationIds.count) invites sent")
    }
  }

  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
    switch error {
    case .some(let error as NSError) where error.code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue:
      GIDSignIn.sharedInstance().signIn()
    case .some(let error as NSError) where error.code == -1009:
      MDCSnackbarManager.show(MDCSnackbarMessage(text: error.localizedDescription))
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

extension UIViewController {
  func displaySpinner() -> UIView {
    let spinnerView = UIView.init(frame: view.bounds)
    spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
    let ai = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
    ai.startAnimating()
    ai.center = spinnerView.center

    DispatchQueue.main.async {
      spinnerView.addSubview(ai)
      self.view.addSubview(spinnerView)
    }
    return spinnerView
  }

  func removeSpinner(_ spinner: UIView) {
    DispatchQueue.main.async {
      spinner.removeFromSuperview()
    }
  }
}
