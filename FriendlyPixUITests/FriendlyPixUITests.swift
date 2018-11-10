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
    let app = XCUIApplication(bundleIdentifier: "com.google.friendlypix.dev")
    app.launch();
    win = app.windows.element(boundBy: 0)
  }

  func testGuestSignIn() {
    acceptAllPermissions()
    acceptPrivacyandTerms()
    signInAsGuest()
    readComment()
  }

  func testFriendlyPix() {
    acceptAllPermissions()
    acceptPrivacyandTerms()
    signInWithGoogle()
    //takeNewPhoto()
    addComment()
  }

  func acceptAllPermissions() {
    addUIInterruptionMonitor(withDescription: "acceptAllPermissions", handler: {
      alert -> Bool in
      for id in ["OK", "Allow", "Continue", "Not now"] {
        if self.tryToTap(alert.buttons[id]) {
          return true
        }
      }
      return false
    })
  }

  func acceptPrivacyandTerms() {
    tryToTap(win.buttons["I agree"], forTimeInterval: 3)
  }

  func signInAsGuest() {
    let signInButton = win.buttons["Sign in as guest"]
    if !signInButton.exists {
      signOut()
    }
    signInButton.tap()
  }

  func signOut() {
    let profileButton = win.buttons["Profile"]
    profileButton.tap()
    let logoutButton = win.buttons["Log out"]
    if !tryToTap(logoutButton) {
      win.buttons["more"].tap()
      win.buttons["Sign out"].tap()
    }
    win.buttons["Logout"].tap()
    win.tap()
    acceptAllPermissions()
    acceptPrivacyandTerms()
  }

  func signInWithGoogle() {
    let signInButton = win.buttons["Sign in with Google"]
    if !signInButton.exists {
      signOut()
    }
    signInButton.tap()

    // Enter email or choose account from account chooser.
    let email = ProcessInfo.processInfo.environment["GOOGLE_EMAIL"]!
    let emailElement = win
      .descendants(matching: .any)
      .matching(NSPredicate(format: "(label == 'Email or phone') || (label CONTAINS[c] %@)", email))
      .element(boundBy: 0)
    if !tryToTap(emailElement, forTimeInterval: 3) {
      win.tap()  // Sometimes need to trigger the permissions dialog first.
    }
    if emailElement.exists {
      emailElement.tap()
    }
    if emailElement.exists, emailElement.label == "Email or phone" {
      emailElement.tap()
      emailElement.typeText(email)
      win.tap()
      tryToTap(win.buttons["Next"], forTimeInterval: 3)
    }

    // Enter the password field if the user is signed out.
    let password = ProcessInfo.processInfo.environment["GOOGLE_PASSWORD"]!
    let passwordField = win.secureTextFields["Enter your password"]
    if tryToTap(passwordField, forTimeInterval: 3) {
      passwordField.typeText(password)
      win.tap()
      tryToTap(win.buttons["Next"], forTimeInterval: 3)
    }

    if tryToTap(win.buttons["Confirm your recovery email"]) {
      win.tap()
    }
  }

  func takeNewPhoto() {
    win.buttons["Open camera"].forceTapElement()
    let takePhotoButton = win.buttons["Take photo"]
    if !tryToTap(takePhotoButton, forTimeInterval: 3) {
      win.tap()
      takePhotoButton.tap()
    }
    let doneButton = win.buttons["Done"]
    if !tryToTap(doneButton, forTimeInterval: 3) {
      // The multiple permissions dialogs can prevent the take photo from happening.
      takePhotoButton.tap()
      if !tryToTap(doneButton, forTimeInterval: 3) {
        // No camera
        win.buttons["Cancel"].tap()
        return
      }
    }
    let captionField = win.textFields.element
    XCTAssert(tryToTap(captionField, forTimeInterval: 3))
    captionField.typeText("my friendly pic")
    win.buttons["UPLOAD THIS PIC"].tap()
  }

  func readComment() {
    XCTAssert(tryToTap(win.buttons.matching(NSPredicate(format: "label == 'comment'")).element(boundBy: 0), forTimeInterval: 3))
    let commentField = win.textViews.element
    commentField.tap()
    XCTAssert(!XCUIApplication().keyboards.element.exists)
  }

  func addComment() {
    XCTAssert(tryToTap(win.buttons.matching(NSPredicate(format: "label == 'comment'")).element(boundBy: 0), forTimeInterval: 3))
    let commentField = win.textViews.element
    commentField.tap()
    commentField.typeText("Nice, pic!")
    win.buttons["Send comment"].tap()
    win.buttons["Back"].tap()
  }

  func tryToTap(_ element: XCUIElement, forTimeInterval ti: Double = 0) -> Bool {
    let startTime = NSDate.timeIntervalSinceReferenceDate
    repeat {
      if element.exists && element.isHittable {
        element.tap()
        return true
      }
    } while NSDate.timeIntervalSinceReferenceDate - startTime < ti
    return false
  }

  func wait(forElement element: XCUIElement, timeout: TimeInterval) {
    let predicate = NSPredicate(format: "exists == 1")

    // This will make the test runner continously evalulate the
    // predicate, and wait until it matches.
    expectation(for: predicate, evaluatedWith: element)
    waitForExpectations(timeout: timeout)
  }
}

  extension XCUIElement {
    func forceTapElement() {
      if self.isHittable {
        self.tap()
      }
      else {
        let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVector(dx:0.0, dy:0.0))
        coordinate.tap()
      }
    }
  }

