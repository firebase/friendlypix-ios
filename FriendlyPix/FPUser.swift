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

class FPUser {
  var uid: String
  var fullname: String
  var profilePictureURL: URL?

  init(snapshot: DataSnapshot) {
    self.uid = snapshot.key
    let value = snapshot.value as! [String: Any]
    self.fullname = value["full_name"] as? String ?? ""
    guard let profile_picture = value["profile_picture"] as? String,
      let profilePictureURL = URL(string: profile_picture) else { return }
    self.profilePictureURL = profilePictureURL
  }

  init(dictionary: [String: String]) {
    self.uid = dictionary["uid"]!
    self.fullname = dictionary["full_name"] ?? ""
    guard let profile_picture = dictionary["profile_picture"],
      let profilePictureURL = URL(string: profile_picture) else { return }
    self.profilePictureURL = profilePictureURL
  }

  private init(user: User) {
    self.uid = user.uid
    self.fullname = user.displayName ?? ""
    self.profilePictureURL = user.photoURL
  }

  static func currentUser() -> FPUser {
    return FPUser(user: Auth.auth().currentUser!)
  }

  func author() -> [String: String] {
    return ["uid": uid, "full_name": fullname, "profile_picture": profilePictureURL?.absoluteString ?? ""]
  }
}

extension FPUser: Equatable {
  static func ==(lhs: FPUser, rhs: FPUser) -> Bool {
    return lhs.uid == rhs.uid
  }
  static func ==(lhs: FPUser, rhs: User) -> Bool {
    return lhs.uid == rhs.uid
  }
}
