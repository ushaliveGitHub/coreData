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

class PetsViewController: UIViewController {
	@IBOutlet private weak var collectionView:UICollectionView!
	//Commented out for replacing array with coreData
	//var petAdded:(()->Void)!
	//var pets = [String]()
    
    private var formatter:DateFormatter = DateFormatter()
    var friend:Friend!
    private var fetchedResultsController:NSFetchedResultsController<Pets>!
    private var query:String? = nil
    private var appDelegate = UIApplication.shared.delegate as! AppDelegate
    private var context = (UIApplication.shared.delegate as! AppDelegate).persistantContainer.viewContext
	private var isFiltered = false
	private var filtered = [String]()
	private var selected:IndexPath!
	private var picker = UIImagePickerController()
    
    //gesture recognizer for long press
    var longPress:UILongPressGestureRecognizer!
    

    override func viewDidLoad() {
        super.viewDidLoad()
		picker.delegate = self
        formatter.dateFormat = "d MM yyyy"
        refresh()
        
        //for long Press
        longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleDelete(_:)))
        longPress.delegate = self
        longPress.delaysTouchesBegan = true
        longPress.minimumPressDuration = 0.5
        self.collectionView.addGestureRecognizer(longPress)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	// MARK:- Actions
	@IBAction func addPet() {
        
		let data = PetData()
        let pet = Pets(entity: Pets.entity(), insertInto: context)
        pet.name = data.name
        pet.dob = data.dob as NSDate
        pet.owner = friend
        pet.kind = data.kind
        appDelegate.saveContext()
        //commented out for NSFetchedResultsController delegate
        //refresh()
        //collectionView.reloadData()
        
        //commented out to replace with CoreData
		/*while pets.contains(pet.name) {
			pet = PetData()
		}
		pets.append(pet.name)
		let index = IndexPath(row:pets.count - 1, section:0)
		collectionView.insertItems(at: [index])
		// Call closure
		petAdded()*/
	}
    
    private func refresh(){
        let request = Pets.fetchRequest() as NSFetchRequest<Pets>
        if let query = query{
            request.predicate = NSPredicate(format:"name CONTAINS[cd] %@ AND owner = %@",query,friend)
        }else{
            request.predicate = NSPredicate(format: "owner = %@", friend)
        }
        let sortByName = NSSortDescriptor(key: #keyPath(Pets.name), ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        request.sortDescriptors = [sortByName]
        
        do{
            fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil) as! NSFetchedResultsController<Friend> as! NSFetchedResultsController<Pets>
            fetchedResultsController.delegate = self //added for NSFetchedResultsController delegate
            try fetchedResultsController.performFetch()
        }catch let error as NSError{
            print("Oops encountered error : \(error), \(error.userInfo)")
        }
        
    }//end of refresh
    
    @objc func handleDelete(_ gesture:UILongPressGestureRecognizer!){
        print("pressed")
        if gesture.state != UIGestureRecognizerState.ended{//if gestureRecognizer is still in progress
            return
        }
        let point = gesture.location(in: self.collectionView)
        guard let indexPath:IndexPath = self.collectionView?.indexPathForItem(at: point)else {
            print("Oops could not delete the item")
            return
        }
        let pet = self.fetchedResultsController.object(at: indexPath)
        context.delete(pet)
        appDelegate.saveContext()
        //commented out for NSFetchedResultsController delegate
        //refresh()
        //collectionView.reloadData()
        //context.delete(indexPath)
    }//end of handleDelete
    
}

// Collection View Delegates
extension PetsViewController: UICollectionViewDelegate, UICollectionViewDataSource,UIGestureRecognizerDelegate {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		//let count = isFiltered ? filtered.count : pets.count
        return fetchedResultsController.fetchedObjects?.count ?? 0
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PetCell", for: indexPath) as! PetCell
		//Commented out to replace wit NSFectechedResults Controller.
        //let pet = isFiltered ? filtered[indexPath.row] : pets[indexPath.row
		let pet = fetchedResultsController.object(at: indexPath)
        cell.nameLabel.text = pet.name
        cell.animalLabel.text = pet.kind
        if let dob = pet.dob as Date?{
            cell.dobLabel.text = formatter.string(from: dob )
        }else{
            cell.dobLabel.text = "Unknown"
        }
        
        if let data = pet.picture as Data?{
            cell.pictureImageView.image = UIImage(data:data)
        }else{
            cell.pictureImageView.image = UIImage(named:"pet-placeholder")
        }
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		selected = indexPath
//		self.navigationController?.present(picker, animated: true, completion: nil)
	}
}

// Search Bar Delegate
extension PetsViewController:UISearchBarDelegate {
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		guard let query = searchBar.text else {
			return
		}
        //commented out for coreData
		/*isFiltered = true
		filtered = pets.filter({(txt) -> Bool in
			return txt.contains(query)
		})*/
        self.query = query
        refresh()
		searchBar.resignFirstResponder()
		collectionView.reloadData()
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		//Commented out for coreData
        /*isFiltered = false
		filtered.removeAll()*/
        self.query = nil
        refresh()
		searchBar.text = nil
		searchBar.resignFirstResponder()
		collectionView.reloadData()
	}
}


extension PetsViewController:NSFetchedResultsControllerDelegate{
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let index = indexPath ?? (newIndexPath ?? nil)  else{
            return
        }
        
        switch type{
            case .insert: collectionView.insertItems(at: [index])
            case .delete: collectionView.deleteItems(at: [index])
            default: break
        }
        
    }
}

// Image Picker Delegates
extension PetsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    let image  = info[UIImagePickerControllerOriginalImage] as! UIImage
		collectionView?.reloadItems(at: [selected])
        let pet = fetchedResultsController.object(at: selected)
        if let data = UIImagePNGRepresentation(image){
            pet.picture = data as NSData
            appDelegate.saveContext()
        }
        collectionView.reloadData()
		picker.dismiss(animated: true, completion: nil)
	}
}
