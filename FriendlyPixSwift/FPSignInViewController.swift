//
//  FPSignInViewController.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 10/3/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import UIKit
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseFacebookAuthUI
import Firebase

private let kFacebookAppID = "FACEBOOK_APP_ID"
private let kFirebaseTermsOfService = URL(string: "https://firebase.google.com/terms/")!

class FPSignInViewController: UIViewController, FUIAuthDelegate {

  fileprivate(set) var authUI: FUIAuth?
  fileprivate var authStateDidChangeHandle: AuthStateDidChangeListenerHandle?

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    authUI = FUIAuth.defaultAuthUI()
    authUI?.delegate = self
    authUI?.tosurl = kFirebaseTermsOfService
    authUI?.isSignInWithEmailHidden = true
    let providers = [FUIGoogleAuth(), FUIFacebookAuth()]
    authUI?.providers = providers as! [FUIAuthProvider]
    let authViewController: UINavigationController? = authUI?.authViewController()
    authViewController?.navigationBar.isHidden = true
    present(authViewController!, animated: true) { _ in }
  }

  func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
    guard let authError = error else {
      signed(in: user!)
      return
    }

    let errorCode = UInt((authError as NSError).code)

    switch errorCode {
    case FUIAuthErrorCode.userCancelledSignIn.rawValue:
      print("User cancelled sign-in");
      break
    default:
      let detailedError = (authError as NSError).userInfo[NSUnderlyingErrorKey] ?? authError
      print("Login error: \((detailedError as! NSError).localizedDescription)");
    }
  }

  func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
    return FPAuthPickerViewController(nibName: "FPAuthPickerViewController", bundle: Bundle.main, authUI: authUI)
  }

  func signed(in user: User) {
    self.performSegue(withIdentifier: "SignInToFP", sender: nil)
  }
}
