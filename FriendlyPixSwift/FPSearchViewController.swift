//
//  FPSearchViewController.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 11/1/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import Firebase
import MaterialComponents

class FPSearchViewController: MDCCollectionViewController {
  let searchController = UISearchController(searchResultsController: nil)
  let peopleRef = Database.database().reference(withPath: "people")
  var people = [FPUser]()
  

  override func viewDidLoad() {
    super.viewDidLoad()
    // Setup the Search Controller
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.hidesNavigationBarDuringPresentation = false
    searchController.searchBar.placeholder = "Search"
    navigationItem.titleView = searchController.searchBar
    definesPresentationContext = true
  }

  func searchBarIsEmpty() -> Bool {
    // Returns true if the text is empty or nil
    if let x = searchController.searchBar.text?.characters.count, x > 2 {
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
    self.collectionView?.reloadData()
    search(searchString, at: "full_name")
    search(searchString, at: "reversed_full_name")
  }

  private func search(_ searchString: String, at index: String) {
    peopleRef.queryOrdered(byChild: "_search_index/\(index)").queryStarting(atValue: searchString)
      .queryLimited(toFirst: 10).observeSingleEvent(of: .value, with: { snapshot in
        let enumerator = snapshot.children
        self.collectionView?.performBatchUpdates({
          while let person = enumerator.nextObject() as? DataSnapshot {
            if let value = person.value as? [String: Any], let searchIndex = value["_search_index"] as? [String: Any],
              let fullName = searchIndex[index] as? String, fullName.hasPrefix(searchString) {
              self.people.append(FPUser(snapshot: person))
              self.collectionView?.insertItems(at: [IndexPath(item: self.people.count - 1, section: 0)])
            }
          }
        }, completion: nil)
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
    if let cell = cell as? MDCCollectionViewTextCell {
      let user = people[indexPath.item]
//    if isFiltering() {
//      candy = filteredCandies[indexPath.row]
//    } else {
//      candy = candies[indexPath.row]
//    }
      if let profilePictureURL = user.profilePictureURL {
        UIImage.circleImage(with: profilePictureURL, to: cell.imageView!)
      }
      cell.textLabel!.text = user.fullname
      cell.textLabel?.numberOfLines = 1
      cell.detailTextLabel?.numberOfLines = 0
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
  // MARK: - UISearchResultsUpdating Delegate
  func updateSearchResults(for searchController: UISearchController) {
    filterContentForSearchText(searchController.searchBar.text!)
  }
}
