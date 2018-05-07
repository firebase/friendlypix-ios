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

import XCTest

// A simple test of FriendlyPix.
class FriendlyPixUITest: XCTestCase {

  var win: XCUIElement!

  open override func setUp() {
    super.setUp()
    continueAfterFailure = false
    let app = XCUIApplication(bundleIdentifier: "com.google.firebase.friendlypix")
    app.launch();
    win = app.windows.element(boundBy: 0)
  }

  func testFriendlyPix() {
    acceptAllPermissions()
    signInWithGoogle()
    takeNewPhoto()
    uploadPhoto()
    addComment()
  }

  func acceptAllPermissions() {
    addUIInterruptionMonitor(withDescription: "acceptAllPermissions", handler: {
      alert -> Bool in
      for id in ["OK", "Allow", "Continue"] {
        if self.tryToTap(alert.buttons[id]) {
          return true
        }
      }
      return false
    })
  }

  func signInWithGoogle() {
    let signInButton = win.buttons["Sign in with Google"]
    if !signInButton.exists {
      return  // Must already be signed in
    }
    signInButton.tap()

    // Enter email or choose account from account chooser.
    let email = ProcessInfo.processInfo.environment["GOOGLE_EMAIL"]!
    let emailElement = win
      .descendants(matching: .any)
      .matching(NSPredicate(format: "(label == 'Email or phone') || (label CONTAINS[c] %@)", email))
      .element
    if !tryToTap(emailElement, forTimeInterval: 3) {
      win.tap()  // Sometimes need to trigger the permissions dialog first.
      XCTAssert(tryToTap(emailElement, forTimeInterval: 3))
    }
    if emailElement.label == "Email or phone" {
      emailElement.typeText(email)
      win.buttons["NEXT"].tap()
    }

    // Enter the password field if the user is signed out.
    let password = ProcessInfo.processInfo.environment["GOOGLE_PASSWORD"]!
    let passwordField = win.secureTextFields["Enter your password"]
    if tryToTap(passwordField, forTimeInterval: 3) {
      passwordField.typeText(password)
      win.buttons["NEXT"].tap()
    }
  }

  func takeNewPhoto() {
    XCTAssert(tryToTap(win.buttons["Open camera"], forTimeInterval: 3))
    let takePhotoButton = win.buttons["Take photo"]
    takePhotoButton.tap()
    let doneButton = win.buttons["Done"]
    if !tryToTap(doneButton, forTimeInterval: 3) {
      // The multiple permissions dialogs can prevent the take photo from happening.
      takePhotoButton.tap()
      XCTAssert(tryToTap(doneButton, forTimeInterval: 3))
    }
  }

  func uploadPhoto() {
    let captionField = win.textFields.element
    captionField.tap()
    captionField.typeText("my friendly pic")
    win.buttons["UPLOAD THIS PIC"].tap()
  }

  func addComment() {
    win.buttons.matching(NSPredicate(format: "label == 'comment'")).element(boundBy: 0).tap()
    let commentField = win.textViews.element
    commentField.tap()
    commentField.typeText("Nice, pic!")
    win.buttons["Send comment"].tap()
    win.buttons["Back"].tap()
  }

  func tryToTap(_ elem: XCUIElement, forTimeInterval ti: Double = 0) -> Bool {
    let startTime = NSDate.timeIntervalSinceReferenceDate
    repeat {
      if elem.exists && elem.isHittable {
        elem.tap()
        return true
      }
    } while NSDate.timeIntervalSinceReferenceDate - startTime < ti
    return false
  }
}
