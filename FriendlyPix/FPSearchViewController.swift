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
  let emptyLabel: UILabel = {
    let messageLabel = UILabel()
    messageLabel.text = "No people found."
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
    // Setup the Search Controller
    searchController.searchResultsUpdater = self
    searchController.searchBar.delegate = self
    searchController.delegate = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.hidesNavigationBarDuringPresentation = false
    searchController.searchBar.placeholder = "Search People"

    UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).leftViewMode = .never
    searchController.searchBar.setImage(#imageLiteral(resourceName: "ic_close"), for: .clear, state: .normal)
    //searchController.searchBar.setImage(#imageLiteral(resourceName: "ic_arrow_back"), for: .search, state: .normal)
    UIImageView.appearance(whenContainedInInstancesOf: [UISearchBar.self]).bounds = CGRect(x: 0, y: 0, width: 24, height: 24)

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
    navigationController?.navigationBar.tintColor = .gray
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.barTintColor = .white
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

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    collectionView.backgroundView = people.isEmpty ? emptyLabel : nil
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
