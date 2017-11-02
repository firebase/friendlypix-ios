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

import UIKit
import SDWebImage

extension UIImage {
  var circle: UIImage? {
    let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
    let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
    imageView.contentMode = .scaleAspectFill
    imageView.image = self
    imageView.layer.cornerRadius = square.width/2
    imageView.layer.masksToBounds = true
    UIGraphicsBeginImageContext(imageView.bounds.size)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    imageView.layer.render(in: context)
    let result = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return result
  }

  static func circleImage(from urlString: String, to imageView: UIImageView) {
    if let image = SDImageCache.shared().imageFromCache(forKey: urlString) {
      imageView.image = image
      return
    }
    SDWebImageDownloader.shared().downloadImage(with: URL.init(string: urlString), options: .highPriority, progress: nil) { (image, data, error, finished) in
      if let image = image {
        let circleImage = image.circle
        SDImageCache.shared().store(circleImage, forKey: urlString, completion: nil)
        imageView.image = circleImage
      }
    }
  }

  static func circleButton(from urlString: String, to button: UIButton) {
    if let image = SDImageCache.shared().imageFromCache(forKey: urlString) {
      button.setImage(image, for: .normal)
      return
    }
    SDWebImageDownloader.shared().downloadImage(with: URL.init(string: urlString), options: .highPriority, progress: nil) { (image, data, error, finished) in
      if let image = image {
        let circleImage = image.circle
        SDImageCache.shared().store(circleImage, forKey: urlString, completion: nil)
        button.setImage(image, for: .normal)
      }
    }
  }

//  static func circleImageView(from url: URL) -> UIImage {
//    let urlString = url.absoluteString
//    if let image = SDImageCache.shared().imageFromCache(forKey: urlString) {
//      return image
//    }
//    SDWebImageDownloader.shared().downloadImage(with: url, options: .highPriority, progress: nil) { (image, data, error, finished) in
//      if let image = image {
//        let circleImage = image.circle
//        SDImageCache.shared().store(circleImage, forKey: urlString, completion: nil)
//        return circleImage
//      }
//    }
  //}
}
