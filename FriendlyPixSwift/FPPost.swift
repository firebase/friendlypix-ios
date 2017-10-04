//
//  FPPost.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 9/29/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import Foundation
import Firebase

class FPPost {
  var postID = ""
  var postDate: Date?
  var imageURL: String?
  var author: FPUser?
  var text = ""
  var comments: [FPComment?]!
  var isLiked = false
  //var likes: [String: String]!

  init(snapshot: DataSnapshot, andComments comments: [FPComment?]) {
    guard let value = snapshot.value as? [String:Any] else { return }
    self.postID = snapshot.key
    self.text = value["text"]! as! String
    let x = value["timestamp"]! as! NSNumber
    self.postDate = Date(timeIntervalSince1970: (x.doubleValue / 1000.0))
    self.author = FPUser.init(dictionary: value["author"] as! [String : String])
    self.imageURL = value["full_url"]! as! String
    self.comments = comments
  }

}
