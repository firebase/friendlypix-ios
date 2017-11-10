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

import SDWebImage

extension UIImage {
  var circle: UIImage? {
    let square = CGSize(width: min(size.width, size.height), height: min(size.width, size.height))
    //let square = CGSize(width: 36, height: 36)
    let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
    imageView.contentMode = .scaleAspectFill
    imageView.image = self
    imageView.layer.cornerRadius = square.width / 2
    imageView.layer.masksToBounds = true
    UIGraphicsBeginImageContext(imageView.bounds.size)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    imageView.layer.render(in: context)
    let result = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return result
  }

  func resizeImage(_ dimension: CGFloat, with quality: CGFloat) -> Data? {
    var width: CGFloat
    var height: CGFloat
    var newImage: UIImage

    let size = self.size
    let aspectRatio =  size.width/size.height

    if aspectRatio > 1 {                            // Landscape image
      width = dimension
      height = dimension / aspectRatio
    } else {                                        // Portrait image
      height = dimension
      width = dimension * aspectRatio
    }

    if #available(iOS 10.0, *) {
      let renderFormat = UIGraphicsImageRendererFormat.default()
      let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
      newImage = renderer.image {
        (context) in
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
      }
    } else {
      UIGraphicsBeginImageContext(CGSize(width: width, height: height))
      self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
      newImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
    }
    return UIImageJPEGRepresentation(newImage, quality)
  }

  static func circleImage(with url: URL, to imageView: UIImageView) {
    let urlString = url.absoluteString
    if let image = SDImageCache.shared().imageFromCache(forKey: urlString) {
      imageView.image = image
      return
    }
    SDWebImageDownloader.shared().downloadImage(with: url,
                                                options: .highPriority, progress: nil) { image, _, error, _ in
      if let error = error {
        print(error)
        return
      }
      if let image = image {
        let circleImage = image.circle
        SDImageCache.shared().store(circleImage, forKey: urlString, completion: nil)
        imageView.image = circleImage
      }
    }
  }

  static func circleButton(with url: URL, to button: UIButton) {
    let urlString = url.absoluteString
    if let image = SDImageCache.shared().imageFromCache(forKey: urlString) {
      button.setImage(image, for: .normal)
      return
    }
    SDWebImageDownloader.shared().downloadImage(with: url, options: .highPriority, progress: nil) { image, _, _, _ in
      if let image = image {
        let circleImage = image.circle
        SDImageCache.shared().store(circleImage, forKey: urlString, completion: nil)
        button.setImage(circleImage, for: .normal)
      }
    }
  }
}
