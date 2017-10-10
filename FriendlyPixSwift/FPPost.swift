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
