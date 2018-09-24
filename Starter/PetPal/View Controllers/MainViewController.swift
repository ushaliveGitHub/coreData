/**
* Copyright (c) 2017 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
* distribute, sublicense, create a derivative work, and/or sell copies of the
* Software in any work that is designed, intended, or marketed for pedagogical or
* instructional purposes related to programming, coding, application development,
* or information technology.  Permission for such use, copying, modification,
* merger, publication, distribution, sublicensing, creation of derivative works,
* or sale is expressly withheld.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import CoreData

class MainViewController: UIViewController {
	@IBOutlet private weak var collectionView:UICollectionView!
	
    //private var friends = [Friend]()
    //private var filtered = [Friend]()
    //private var isFiltered = false
    //private var images = [String:UIImage]()
    
    private var query:String? = nil
    private var fetchedResultsController:NSFetchedResultsController<Friend>!
    private var appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistantContainer.viewContext
	private var friendPets = [String:[String]]()
	private var selected:IndexPath!
	private var picker = UIImagePickerController()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //commented after refactoring
        /*do{
            friends = try context.fetch(Friend.fetchRequest())
        }catch let error as NSError{
            print("Oops something went wrong, could not fetch:\(error),\(error.userInfo)")
        }*/
        refresh()
        showEditButton()
    }

	override func viewDidLoad() {
		super.viewDidLoad()
		picker.delegate = self
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK:- Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "petSegue" {
			if let index = sender as? IndexPath {
				let pvc = segue.destination as! PetsViewController
				//let friend = friends[index.row]
                let friend = fetchedResultsController.object(at: index)
                pvc.friend = friend
                //commented out for CoreData refactoring
                /*if let pets = friendPets[friend.name!] {
					pvc.pets = pets
				}
				pvc.petAdded = {
                    self.friendPets[friend.name!] = pvc.pets
				}*/
			}
		}
	}

	// MARK:- Actions
	@IBAction func addFriend() {
        let data = FriendData()
		let friend = Friend(entity: Friend.entity(), insertInto: context)
        friend.name = data.name
        friend.address = data.address
        friend.dob = data.dob as NSDate
        friend.eyeColor = data.eyeColor
        appDelegate.saveContext()
        //friends.append(friend) // not needed if we refresh collection view
        //let index = IndexPath(row: friends.count - 1, section: 0)
        //collectionView?.insertItems(at: [index])// not needed if we refresh collection view
        refresh()
        collectionView.reloadData()
	}
	
	// MARK:- Private Methods
	private func showEditButton() {
		//if friends.count > 0 { //commented out for NSFecthedResultsController
        if let count = fetchedResultsController.fetchedObjects?.count, count > 0{
			navigationItem.leftBarButtonItem = editButtonItem
		}
	}
}

// Collection View Delegates
extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView( ofKind:kind, withReuseIdentifier: "HeaderRow", for: indexPath)
        if let label = view.viewWithTag(1000) as? UILabel{
            if let friends = fetchedResultsController.sections?[indexPath.section].objects as? [Friend], let friend = friends.first{
                label.text = "EyeColor:\(friend.eyeColorName)"
            }
        }
        return view
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		//let count = isFiltered ? filtered.count : friends.count
        //let count = friends.count //commented out for NSFetchedResults controller
        guard let sections = fetchedResultsController.sections, let objects = sections[section].objects else{
            return 0
        }
        return objects.count
        //commented out for sections implementation
        //let count = fetchedResultsController.fetchedObjects?.count ?? 0
        //return count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendCell", for: indexPath) as! FriendCell
		//let friend = isFiltered ? filtered[indexPath.row] : friends[indexPath.row] //For array before CoreData use
        //let friend = friends[indexPath.row] //commented out for NSFetchedController
        let friend = fetchedResultsController.object(at: indexPath)
		cell.nameLabel.text = friend.name!
        cell.addressLabel.text = friend.address
        cell.ageLabel.text = "Age: \(friend.age)"
        cell.eyeColorView.backgroundColor = friend.eyeColor as? UIColor
		//commented for Array
        /*if let image = images[friend.name!] {
			cell.pictureImageView.image = image
		}*/
        if let data = friend.picture as Data? {
            cell.pictureImageView.image = UIImage(data:data)
        }else{
            cell.pictureImageView.image = UIImage(named:"person-placeholder")
        }
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		if isEditing {
			selected = indexPath
			self.navigationController?.present(picker, animated: true, completion: nil)
		} else {
			performSegue(withIdentifier: "petSegue", sender: indexPath)
		}
	}
    
    private func refresh(){
        let request = Friend.fetchRequest() as NSFetchRequest<Friend>
        if let query = self.query{
            request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
        }
        let sortByName = NSSortDescriptor(key: #keyPath(Friend.name), ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        let sortByEyecolor = NSSortDescriptor(key: #keyPath(Friend.eyeColor), ascending: true)
        request.sortDescriptors = [sortByEyecolor,sortByName]
        do{
            //commented to allow sorting
            //friends = try context.fetch(Friend.fetchRequest())
            //commented out for NSFetchedResults controller
            //friends = try context.fetch(request)
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: #keyPath(Friend.eyeColor), cacheName: nil)
            try fetchedResultsController.performFetch()
        }catch let error as NSError{
            print("Oops something went wrong, could not fetch:\(error),\(error.userInfo)")
        }
    }
}

// Search Bar Delegate
extension MainViewController:UISearchBarDelegate {
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		guard let query = searchBar.text else {
			return
		}
		
        //commented for Array
        //isFiltered = true
		//filtered = friends.filter({(friend) -> Bool in
		//	return friend.name!.contains(query)
		//})
        self.query = query
        //commented out to do all sorts and query in one place
        /*let fetchRequest = Friend.fetchRequest() as NSFetchRequest<Friend>
        fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
        //commented out to perform case insensitive sort
        //let sortKeys = NSSortDescriptor(keyPath: \Friend.name, ascending: true)
        let sortKeys = NSSortDescriptor(key: #keyPath(Friend.name), ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        fetchRequest.sortDescriptors = [sortKeys]
        do{
            try friends = context.fetch(fetchRequest)
        }catch let error as NSError {
            print("Oops encountered Error: \(error) , \(error.userInfo)")
        }*/
        refresh()
		searchBar.resignFirstResponder()
		collectionView.reloadData()
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		/*isFiltered = false
		filtered.removeAll()*/
        self.query = nil
        refresh()
		searchBar.text = nil
		searchBar.resignFirstResponder()
		collectionView.reloadData()
	}
}

// Image Picker Delegates
extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        //commented out for NSFetchedResults controller
		//let friend = isFiltered ? filtered[selected.row] : friends[selected.row]
        //let friend = friends[selected.row]
        //images[friend.name!] = image
        let friend = fetchedResultsController.object(at: selected)
        if let data = UIImagePNGRepresentation(image){
            friend.picture = data as NSData
            appDelegate.saveContext()
        }
		
		collectionView?.reloadItems(at: [selected])
		picker.dismiss(animated: true, completion: nil)
	}
}


