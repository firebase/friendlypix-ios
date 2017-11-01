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

import Foundation
import Firebase

class FPUser {
  var userID = ""
  var fullname = ""
  var profilePictureURL = ""


  convenience init(snapshot: DataSnapshot) {
    self.init()
    guard let value = snapshot.value as? [String:String] else { return }
    self.userID = snapshot.key
    self.fullname = value["full_name"]!
    self.profilePictureURL = value["profile_picture"]!
  }

  convenience init(dictionary: [String:String]) {
    self.init()
    self.userID = dictionary["uid"]!
    self.fullname = dictionary["full_name"]!
    self.profilePictureURL = dictionary["profile_picture"]!
  }

  func author() -> [String: String] {
    return ["uid": userID, "full_name": fullname, "profile_picture": profilePictureURL]
  }

}


