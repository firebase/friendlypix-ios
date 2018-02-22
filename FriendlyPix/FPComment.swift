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

class FPComment {
  var commentID: String
  var text: String
  var postDate: Date
  var from: FPUser

  init(snapshot: DataSnapshot) {
    self.commentID = snapshot.key
    let value = snapshot.value as! [String: Any]
    self.text = value["text"] as? String ?? ""
    let timestamp = value["timestamp"] as! Double
    self.postDate = Date(timeIntervalSince1970: timestamp / 1_000.0)
    let author = value["author"] as! [String: String]
    self.from = FPUser(dictionary: author)
  }
}

extension FPComment: Equatable {
  static func ==(lhs: FPComment, rhs: FPComment) -> Bool {
    return lhs.commentID == rhs.commentID && lhs.postDate == rhs.postDate
  }
}
