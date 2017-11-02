//
//  FPSearchViewController.swift
//  FriendlyPixSwift
//
//  Created by Ibrahim Ulukaya on 11/1/17.
//  Copyright © 2017 Ibrahim Ulukaya. All rights reserved.
//

import UIKit
import MaterialComponents.MaterialCollections
import Firebase

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
    searchController.searchBar.placeholder = "Search Candies"
    navigationItem.titleView = searchController.searchBar
    definesPresentationContext = true
  }

  func searchBarIsEmpty() -> Bool {
    // Returns true if the text is empty or nil
    if let x = searchController.searchBar.text?.characters.count, x>2 {
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
    peopleRef.queryOrdered(byChild: "_search_index/full_name").queryStarting(atValue: searchString).queryLimited(toFirst: 10).observeSingleEvent(of: .value, with: { (snapshot) in
      self.collectionView?.performBatchUpdates({
        for person in snapshot.children {
          let x = person as! DataSnapshot
          let y = x.value as! [String:Any]
          let z = y["_search_index"] as! [String:Any]
          if let t = z["full_name"] as? String, t.hasPrefix(searchString) {
          self.people.append(FPUser.init(snapshot: person as! DataSnapshot))
          self.collectionView?.insertItems(at: [IndexPath.init(item: self.people.count-1, section: 0)])
          }
        }
      }, completion: nil)
    })
    peopleRef.queryOrdered(byChild: "_search_index/reversed_full_name").queryStarting(atValue: searchString).queryLimited(toFirst: 10).observeSingleEvent(of: .value, with: { (snapshot) in
      self.collectionView?.performBatchUpdates({
        for person in snapshot.children {
          let x = person as! DataSnapshot
          let y = x.value as! [String:Any]
          let z = y["_search_index"] as! [String:Any]
          if let t = z["reversed_full_name"] as? String, t.hasPrefix(searchString) {
          self.people.append(FPUser.init(snapshot: person as! DataSnapshot))
          self.collectionView?.insertItems(at: [IndexPath.init(item: self.people.count-1, section: 0)])
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

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MDCCollectionViewTextCell
    let user = people[indexPath.item]
//    if isFiltering() {
//      candy = filteredCandies[indexPath.row]
//    } else {
//      candy = candies[indexPath.row]
//    }
    UIImage.circleImage(from: user.profilePictureURL, to: cell.imageView!)
    cell.textLabel!.text = user.fullname
    return cell
  }
}

extension FPSearchViewController: UISearchResultsUpdating {
  // MARK: - UISearchResultsUpdating Delegate
  func updateSearchResults(for searchController: UISearchController) {
    filterContentForSearchText(searchController.searchBar.text!)
  }
}
