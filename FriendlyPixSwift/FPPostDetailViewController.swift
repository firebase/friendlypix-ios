//
//  PostDetailViewController.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 11/2/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import UIKit
import Firebase

class FPPostDetailViewController: FPFeedViewController {
  var postSnapshot: DataSnapshot!

  override func loadData() {
    if posts.isEmpty {
      super.loadPost(postSnapshot)
    }
  }

  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
  }

  override func showProfile(_ author: FPUser) {
    let x = self.parent?.childViewControllers[0].childViewControllers[0] as! FPFeedViewController
    x.performSegue(withIdentifier: "account", sender: author)
  }

  override func viewComments(_ post: FPPost) {
    let x = self.parent?.childViewControllers[0].childViewControllers[0] as! FPFeedViewController
    x.performSegue(withIdentifier: "comment", sender: post)
  }
}
