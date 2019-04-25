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
import MaterialComponents

class FPSearchViewController: UICollectionViewController, UISearchBarDelegate, UISearchControllerDelegate {
  
  let searchController = UISearchController(searchResultsController: nil)
  let peopleRef = Database.database().reference(withPath: "people")
  let hashtagsRef = Database.database().reference(withPath: "hashtags")
  lazy var appDelegate = UIApplication.shared.delegate as! AppDelegate
  lazy var uid = Auth.auth().currentUser!.uid
  var people = [FPUser]()
  var hashtags = [String]()
  let emptyLabel: UILabel = {
    let messageLabel = UILabel()
    messageLabel.text = "No people or hashtag found."
    messageLabel.textColor = UIColor.black
    messageLabel.numberOfLines = 0
    messageLabel.textAlignment = .center
    messageLabel.font = UIFont.preferredFont(forTextStyle: .title3)
    messageLabel.sizeToFit()
    return messageLabel
  }()
  // We keep track of the pending work item as a property
  private var pendingRequestWorkItem: DispatchWorkItem?

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.register(MDCSelfSizingStereoCell.self, forCellWithReuseIdentifier: "cell")
    // Setup the Search Controller
    searchController.searchResultsUpdater = self
    searchController.searchBar.delegate = self
    searchController.delegate = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.hidesNavigationBarDuringPresentation = false
    searchController.searchBar.placeholder = "Search"

    UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).leftViewMode = .never
    searchController.searchBar.setImage(#imageLiteral(resourceName: "ic_close"), for: .clear, state: .normal)
    //searchController.searchBar.setImage(#imageLiteral(resourceName: "ic_arrow_back"), for: .search, state: .normal)
    UIImageView.appearance(whenContainedInInstancesOf: [UISearchBar.self]).bounds = CGRect(x: 0, y: 0, width: 24, height: 24)

    guard let collectionViewLayout = self.collectionViewLayout as? UICollectionViewFlowLayout else { return }

    collectionViewLayout.estimatedItemSize = CGSize(width: collectionView.bounds.size.width,
                                                    height: 75)

    let x = UIButton.init()
    x.setImage(#imageLiteral(resourceName: "ic_arrow_back"), for: .normal)
    x.addTarget(self, action: #selector(back), for: .touchUpInside)

    UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).translatesAutoresizingMaskIntoConstraints = false
    UIButton.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -4)

    navigationItem.leftBarButtonItem = UIBarButtonItem(customView: x)

    navigationItem.titleView = searchController.searchBar
    navigationItem.hidesBackButton = true
    definesPresentationContext = true
    searchController.searchBar.showsCancelButton = false

    UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.init(red: 0, green: 137/255, blue: 249/255, alpha: 1)
  }

  @objc func back() {
   navigationController?.popViewController(animated: true)
  }

  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchController.searchBar.showsCancelButton = false
    self.searchController.searchBar.becomeFirstResponder()
  }

  func didPresentSearchController(_ searchController: UISearchController) {
    searchController.searchBar.showsCancelButton = false
    self.searchController.searchBar.becomeFirstResponder()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    DispatchQueue.global(qos: .default).async(execute: {() -> Void in
      DispatchQueue.main.async(execute: {() -> Void in
        self.searchController.searchBar.becomeFirstResponder()
      })
    })
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.barTintColor = .white
    navigationController?.navigationBar.tintColor = .gray
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.navigationBar.barTintColor = UIColor.init(hex: "0288D1")
    navigationController?.navigationBar.tintColor = .white
  }

  func filterContentForSearchText(_ searchText: String, scope: String = "All") {
    if searchText.isEmpty {
      return
    }
    let searchString = searchText.lowercased()
    // Cancel the currently pending item
    pendingRequestWorkItem?.cancel()

    // Wrap our request in a work item
    let requestWorkItem = DispatchWorkItem { [weak self] in
      self?.people = [FPUser]()
      self?.hashtags = [String]()
      self?.collectionView?.reloadData()
      self?.collectionView?.performBatchUpdates({
        self?.search(searchString, at: "full_name")
        self?.search(searchString, at: "reversed_full_name")
        self?.searchHashtags(searchString)
      }, completion: nil)
    }

    // Save the new work item and execute it after 250 ms
    pendingRequestWorkItem = requestWorkItem
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250),
                                  execute: requestWorkItem)
  }

  private func search(_ searchString: String, at index: String) {
    peopleRef.queryOrdered(byChild: "_search_index/\(index)").queryStarting(atValue: searchString)
      .queryLimited(toFirst: 10).observeSingleEvent(of: .value, with: { snapshot in
        let enumerator = snapshot.children
          while let person = enumerator.nextObject() as? DataSnapshot {
            if !self.appDelegate.isBlocked(by: person.key), let value = person.value as? [String: Any], let searchIndex = value["_search_index"] as? [String: Any],
              let fullName = searchIndex[index] as? String, fullName.hasPrefix(searchString) {
              self.people.append(FPUser(snapshot: person))
              self.collectionView?.insertItems(at: [IndexPath(item: self.people.count - 1, section: 0)])
            }
          }
    })
  }

  private func searchHashtags(_ searchString: String) {
    hashtagsRef.queryOrderedByKey().queryStarting(atValue: searchString)
      .queryLimited(toFirst: 10).observeSingleEvent(of: .value, with: { snapshot in
      let enumerator = snapshot.children
      while let hashtag = enumerator.nextObject() as? DataSnapshot {
        let tag = hashtag.key
        if tag.hasPrefix(searchString) {
          self.hashtags.append(tag)
          self.collectionView?.insertItems(at: [IndexPath(item: self.hashtags.count - 1, section: 1)])
        }
      }
    })
  }

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 2
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    collectionView.backgroundView = people.isEmpty && hashtags.isEmpty ? emptyLabel : nil
    if section == 0 {
      return people.count
    } else {
      return hashtags.count
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    if let cell = cell as? MDCSelfSizingStereoCell {
      cell.trailingImageView.isHidden = true
      if indexPath.section == 0 {
        let user = people[indexPath.item]
        if let profilePictureURL = user.profilePictureURL {
          UIImage.circleImage(with: profilePictureURL, to: cell.leadingImageView)
        } else {
          cell.leadingImageView.image = #imageLiteral(resourceName: "ic_account_circle_36pt")
        }
        cell.titleLabel.text = user.fullname
      } else {
        cell.leadingImageView.image = #imageLiteral(resourceName: "ic_trending_up")
        cell.titleLabel.text = hashtags[indexPath.item]
      }
      cell.titleLabel.numberOfLines = 1
      cell.detailLabel.numberOfLines = 0
    }
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if indexPath.section == 0 {
      feedViewController.showProfile(people[indexPath.item])
    } else {
      feedViewController.showTaggedPhotos(hashtags[indexPath.item])
    }
  }
}

extension FPSearchViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    filterContentForSearchText(searchController.searchBar.text!)
  }
}
