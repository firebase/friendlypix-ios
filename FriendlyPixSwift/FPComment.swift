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
import Foundation
import MHPrettyDate

class FPComment {
  var commentID = ""
  var text = ""
  var postDate: Date!
  var from: FPUser!

  init(snapshot: DataSnapshot) {
    self.commentID = snapshot.key
    guard let value = snapshot.value as? [String: Any] else { return }
    self.text = value["text"] as? String ?? ""
    guard let timestamp = value["timestamp"] as? Double else { return }
    self.postDate = Date(timeIntervalSince1970: timestamp / 1_000.0)
    guard let author = value["author"] as? [String: String] else { return }
    self.from = FPUser(dictionary: author)
  }
}
