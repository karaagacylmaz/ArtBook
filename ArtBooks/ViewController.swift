//
//  ViewController.swift
//  ArtBooks
//
//  Created by Yılmaz Karaağaç on 1/10/22.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var nameArray = [String]()
    var idArray = [UUID]()
    var selectedPainting = ""
    var selectedPaintingId : UUID?
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked))
        
        getData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //get data from other VC.
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue: "newdata"), object: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row]
        return cell
    }
    
    @objc func getData() {
        cleanArrays()
        let context = getContext()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Painting")
        fetchRequest.returnsObjectsAsFaults = false //about cache. search
        do {
            let result = try context.fetch(fetchRequest)
            
            if result.count > 0 {
                for res in result as! [NSManagedObject] {
                    if let name = res.value(forKey: "name") as? String {
                        self.nameArray.append(name)
                    }
                    
                    if let id = res.value(forKey: "id") as? UUID {
                        self.idArray.append(id)
                    }
                    
                    //data updated. tell ui
                    self.tableView.reloadData()
                }
            }
        } catch {
            print("error in get data")
        }
    }
    
    func getContext() -> NSManagedObjectContext {
        //Access to Core Data start
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        //Access to Core Data end
        return context
    }
    
    @objc func addButtonClicked() {
        selectedPainting = ""
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    
    func cleanArrays() {
        nameArray.removeAll(keepingCapacity: false)
        idArray.removeAll(keepingCapacity: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailVC" {
            let destinationVC = segue.destination as! DetailsViewController
            destinationVC.chosenPainting = selectedPainting
            destinationVC.chosenPaintingId = selectedPaintingId
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPainting = nameArray[indexPath.row]
        selectedPaintingId = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = getContext()
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Painting")
            let idString = idArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let result = try context.fetch(fetchRequest)
                if result.count > 0 {
                    for res in result as! [NSManagedObject] {
                        if let id = res.value(forKey: "id") as? UUID {
                            if id.uuidString == idString {
                                context.delete(res)
                                nameArray.remove(at: indexPath.row)
                                idArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                saveChanges(context: context)
                            }
                        }
                    }
                }
            } catch {
                print("error")
            }
        }
    }
    
    func saveChanges(context: NSManagedObjectContext) {
        do {
            try context.save()
            print("success delete")
        } catch {
            print("error")
        }
    }

    //Core Data keeps data in phone's disk. Local database
    //There is data model file in this project. It's name is ArtBooks.xcdatamodeld
    //Please check data model
    
}

