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
import FirebaseAuthUI
import FirebaseFacebookAuthUI
import FirebaseGoogleAuthUI

private let kFacebookAppID = "FACEBOOK_APP_ID"
private let kFirebaseTermsOfService = URL(string: "https://firebase.google.com/terms/")!

class FPSignInViewController: UINavigationController, FUIAuthDelegate {

  fileprivate(set) var authUI: FUIAuth?
  fileprivate var authStateDidChangeHandle: AuthStateDidChangeListenerHandle?

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if Auth.auth().currentUser != nil {
      self.navigationBar.isHidden = false
      self.performSegue(withIdentifier: "SignInToFP", sender: nil)
      return
    }
    authUI = FUIAuth.defaultAuthUI()
    authUI?.delegate = self
    authUI?.tosurl = kFirebaseTermsOfService
    authUI?.isSignInWithEmailHidden = true
    let providers: [FUIAuthProvider] = [FUIGoogleAuth(), FUIFacebookAuth()]
    authUI?.providers = providers
    let authViewController: UINavigationController? = authUI?.authViewController()
    authViewController?.navigationBar.isHidden = true
    present(authViewController!, animated: true, completion: nil)
  }

  func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
    switch error {
    case .some(let error as NSError) where UInt(error.code) == FUIAuthErrorCode.userCancelledSignIn.rawValue:
      print("User cancelled sign-in")
    case .some(let error as NSError) where error.userInfo[NSUnderlyingErrorKey] != nil:
      print("Login error: \(error.userInfo[NSUnderlyingErrorKey]!)")
    case .some(let error):
      print("Login error: \(error.localizedDescription)")
    case .none:
      if let user = user {
        signed(in: user)
      }
    }
  }

  func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
    return FPAuthPickerViewController(nibName: "FPAuthPickerViewController", bundle: Bundle.main, authUI: authUI)
  }

  func signed(in user: User) {
    // TODO: Create user

  }

}
