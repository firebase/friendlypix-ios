//
//  FPCollectionViewTextCell.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 11/1/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import MaterialComponents
import UIKit

class FPCollectionViewTextCell: MDCCollectionViewTextCell {
  override func prepareForReuse() {
    super.prepareForReuse()
    textLabel?.numberOfLines = 0
    detailTextLabel?.numberOfLines = 0
    setNeedsLayout()
  }
}
