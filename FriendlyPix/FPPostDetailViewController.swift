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

class FPPostDetailViewController: FPFeedViewController {
  var postSnapshot: DataSnapshot!

  override func loadData() {
    if let post = posts.first {
      postsRef.child(post.postID).observeSingleEvent(of: .value, with: {
        if $0.exists() {
          let indexPath = [IndexPath(item: 0, section: 0)]
          self.updatePost(post, postSnapshot: $0, at: indexPath)
          self.listenPost(post, at: indexPath)
        } else {
          self.navigationController?.popViewController(animated: true)
        }
      })
    } else {
      loadPost(postSnapshot)
    }
  }

  override func deletePost(_ post: FPPost, completion: (() -> Swift.Void)? = nil) {
    super.deletePost(post, completion: { self.navigationController?.popViewController(animated: true) })
  }

  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
  }

  override func awakeFromNib() {
  }

  override func showProfile(_ profile: FPUser) {
    feedViewController?.showProfile(profile)
  }

  override func viewComments(_ post: FPPost) {
    feedViewController?.viewComments(post)
  }
}
