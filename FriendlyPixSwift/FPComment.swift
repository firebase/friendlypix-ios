//
//  FPComment.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 9/29/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import Foundation
import Firebase

class FPComment {
  var commentID = ""
  var text = ""
  var postDate: Date?
  var from: FPUser?

  init(snapshot: DataSnapshot) {
    self.commentID = snapshot.key
    guard let value = snapshot.value as? [String:String] else { return }
    self.text = value["text"]!
    self.postDate = Date(timeIntervalSince1970: (Double(value["timestamp"]!)! / 1000.0))
    self.from = FPUser.init(dictionary: value)
  }
}
