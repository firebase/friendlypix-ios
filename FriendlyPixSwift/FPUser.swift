//
//  FPUser.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 9/29/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import Foundation
import Firebase

class FPUser {
  var userID = ""
  var fullname = ""
  var profilePictureURL = ""

  init(snapshot: DataSnapshot) {
    guard let value = snapshot.value as? [String:String] else { return }
    self.userID = snapshot.key
    self.fullname = value["full_name"]!
    self.profilePictureURL = value["profile_picture"]!
  }

  init(dictionary: [String:String]) {
    self.userID = dictionary["uid"]!
    self.fullname = dictionary["full_name"]!
    self.profilePictureURL = dictionary["profile_picture"]!
  }

  func author() -> [String: String] {
    return ["uid": userID, "full_name": fullname, "profile_picture": profilePictureURL]
  }

}


