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

class FPSearchViewController: MDCCollectionViewController, UISearchBarDelegate, UISearchControllerDelegate {
  let searchController = UISearchController(searchResultsController: nil)
  let peopleRef = Database.database().reference(withPath: "people")
  var people = [FPUser]()
  // We keep track of the pending work item as a property
  private var pendingRequestWorkItem: DispatchWorkItem?

  override func viewDidLoad() {
    super.viewDidLoad()
    // Setup the Search Controller
    searchController.searchResultsUpdater = self
    searchController.searchBar.delegate = self
    searchController.delegate = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.hidesNavigationBarDuringPresentation = false
    searchController.searchBar.placeholder = "Search People"
    UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).leftViewMode = .never
    searchController.searchBar.setImage(#imageLiteral(resourceName: "ic_close"), for: .clear, state: .normal)
    navigationItem.hidesBackButton = true
    navigationItem.titleView = searchController.searchBar
    definesPresentationContext = true
searchController.searchBar.showsCancelButton = false
    navigationController?.navigationBar.barTintColor = .white
    UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = .darkGray
  }

  @IBAction func backPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
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
    navigationController?.navigationBar.barTintColor = .white
    DispatchQueue.global(qos: .default).async(execute: {() -> Void in
      DispatchQueue.main.async(execute: {() -> Void in
        self.searchController.searchBar.becomeFirstResponder()
      })
    })
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.navigationBar.barTintColor = UIColor.init(hex: "0288D1")
  }

  func searchBarIsEmpty() -> Bool {
    // Returns true if the text is empty or nil
    if let x = searchController.searchBar.text?.count, x > 2 {
      return false
    }
    return true
  }

  func filterContentForSearchText(_ searchText: String, scope: String = "All") {
    if searchBarIsEmpty() {
      return
    }
    let searchString = searchText.lowercased()
    people = [FPUser]()
    // Cancel the currently pending item
    pendingRequestWorkItem?.cancel()

    // Wrap our request in a work item
    let requestWorkItem = DispatchWorkItem { [weak self] in
            self?.collectionView?.reloadData()
      self?.collectionView?.performBatchUpdates({
      self?.search(searchString, at: "full_name")
      self?.search(searchString, at: "reversed_full_name")
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
            if let value = person.value as? [String: Any], let searchIndex = value["_search_index"] as? [String: Any],
              let fullName = searchIndex[index] as? String, fullName.hasPrefix(searchString) {
              self.people.append(FPUser(snapshot: person))
              self.collectionView?.insertItems(at: [IndexPath(item: self.people.count - 1, section: 0)])
            }
          }
    })
  }

  func isFiltering() -> Bool {
    return searchController.isActive && !searchBarIsEmpty()
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return people.count
  }

  override func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
    if let cell = cell as? FPSearchCell {
      let user = people[indexPath.item]
      if let profilePictureURL = user.profilePictureURL {
        UIImage.circleImage(with: profilePictureURL, to: cell.imageView!)
      }
      cell.textLabel!.text = user.fullname
      cell.textLabel?.numberOfLines = 1
      //cell.detailTextLabel?.numberOfLines = 0
    }
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
    return MDCCellDefaultOneLineWithAvatarHeight
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    feedViewController?.showProfile(people[indexPath.item])
  }
}

extension FPSearchViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    filterContentForSearchText(searchController.searchBar.text!)
  }
}
