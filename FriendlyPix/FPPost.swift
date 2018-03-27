//
//  Copyright (c) 2018 Google Inc.
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

class FPPost {
  var postID: String
  var postDate: Date
  var thumbURL: URL
  var fullURL: URL
  var author: FPUser
  var text: String
  var comments: [FPComment]
  var isLiked = false
  var mine = false
  var likeCount = 0

  convenience init(snapshot: DataSnapshot, andComments comments: [FPComment], andLikes likes: [String: Any]?) {
    self.init(id: snapshot.key, value: snapshot.value as! [String : Any], andComments: comments, andLikes: likes)
  }

  init(id: String, value: [String: Any], andComments comments: [FPComment], andLikes likes: [String: Any]?) {
    self.postID = id
    self.text = value["text"] as! String
    let timestamp = value["timestamp"] as! Double
    self.postDate = Date(timeIntervalSince1970: (timestamp / 1_000.0))
    let author = value["author"] as! [String: String]
    self.author = FPUser(dictionary: author)
    self.thumbURL = URL(string: value["thumb_url"] as! String)!
    self.fullURL = URL(string: value["full_url"] as! String)!
    self.comments = comments
    if let likes = likes {
      likeCount = likes.count
      if let uid = Auth.auth().currentUser?.uid {
        isLiked = (likes.index(forKey: uid) != nil)
      }
    }
    self.mine = self.author == Auth.auth().currentUser!
  }
}

extension FPPost: Equatable {
  static func ==(lhs: FPPost, rhs: FPPost) -> Bool {
    return lhs.postID == rhs.postID
  }
}
