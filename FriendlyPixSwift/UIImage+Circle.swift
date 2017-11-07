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
    //let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
    let square = CGSize(width: 36, height: 36)
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
    let circleString = "\(urlString).circle"
    if let image = SDImageCache.shared().imageFromCache(forKey: circleString) {
      imageView.image = image
      return
    } else if let image = SDImageCache.shared().imageFromCache(forKey: urlString) {
      let circleImage = image.circle
      imageView.image = circleImage
      SDImageCache.shared().store(circleImage, forKey: circleString, completion: nil)
      return
    }
    SDWebImageDownloader.shared().downloadImage(with: URL.init(string: urlString), options: .highPriority, progress: nil) { (image, data, error, finished) in
      if let image = image {
        let circleImage = image.circle
        SDImageCache.shared().store(image, forKey: urlString, completion: nil)
        SDImageCache.shared().store(circleImage, forKey: circleString, completion: nil)
        imageView.image = circleImage
      }
    }
  }

  static func circleButton(from urlString: String, to button: UIButton) {
    let circleString = "\(urlString).circle"
    if let image = SDImageCache.shared().imageFromCache(forKey: circleString) {
      button.setImage(image, for: .normal)
      return
    } else if let image = SDImageCache.shared().imageFromCache(forKey: urlString) {
      let circleImage = image.circle
      button.setImage(circleImage, for: .normal)
      SDImageCache.shared().store(circleImage, forKey: circleString, completion: nil)
      return
    }
    SDWebImageDownloader.shared().downloadImage(with: URL.init(string: urlString), options: .highPriority, progress: nil) { (image, data, error, finished) in
      if let image = image {
        let circleImage = image.circle
        SDImageCache.shared().store(image, forKey: urlString, completion: nil)
        SDImageCache.shared().store(circleImage, forKey: circleString, completion: nil)
        button.setImage(circleImage, for: .normal)
      }
    }
  }
}
