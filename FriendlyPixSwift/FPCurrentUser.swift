//
//  FPCurrentUser.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 10/31/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import Foundation

final class FPCurrentUser {
  private init() {}
  static let shared = FPCurrentUser()
  var user : FPUser!
}
