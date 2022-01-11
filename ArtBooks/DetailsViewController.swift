//
//  DetailsViewController.swift
//  ArtBooks
//
//  Created by Yılmaz Karaağaç on 1/11/22.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var artistText: UITextField!
    @IBOutlet weak var yearText: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    var chosenPainting = ""
    var chosenPaintingId: UUID?
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.isHidden = true //Or isEnabled = false
        //Core Data
        if chosenPainting != "" {
            let context = getContext()
            let fetchRequest = prepareRequest()
            
            do {
                let result = try context.fetch(fetchRequest)
                if result.count > 0 {
                    setDataToControls(result: result)
                }
            } catch {
                print("error")
            }
        }
        
        addRecognizers()
        
        // Do any additional setup after loading the view.
    }
    
    func addRecognizers() {
        //Close Keyboard start
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        //Close Keyboard end
        
        imageView.isUserInteractionEnabled = true
        let imageTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(selectImage))
        imageView.addGestureRecognizer(imageTapRecognizer)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc func selectImage() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true //zoom, crop etc.
        present(picker, animated: true, completion: nil)
    }
    
    //didfinishpicking
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.editedImage] as? UIImage //or original image
        self.dismiss(animated: true, completion: nil)
        saveButton.isHidden = false
        //Info: Older versions of iOS we have to permission for gallery or camera.
        //Info.plist file is necessary for this process. We can choose "Privacy - Photo library usage description" option
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        let context = getContext()
        setPaintingData(context: context)
        saveChanges(context: context)
        goBack()
    }
    
    func getContext() -> NSManagedObjectContext {
        //Access to Core Data start
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        //Access to Core Data end
        return context
    }
    
    func setPaintingData(context: NSManagedObjectContext) {
        let newPainting = NSEntityDescription.insertNewObject(forEntityName: "Painting", into: context)
        newPainting.setValue(nameText.text!, forKey: "name")
        newPainting.setValue(artistText.text, forKey: "artist")
        if let year = Int(yearText.text!) {
            newPainting.setValue(year, forKey: "year")
        }
        newPainting.setValue(UUID(), forKey: "id")
        
        let data = imageView.image?.jpegData(compressionQuality: 0.5)
        newPainting.setValue(data, forKey: "image")
    }
    
    func saveChanges(context: NSManagedObjectContext) {
        do {
            try context.save()
            print("success")
        } catch {
            print("error")
        }
    }
    
    func goBack() {
        NotificationCenter.default.post(name: NSNotification.Name("newdata"), object: nil)
        self.navigationController?.popViewController(animated: true)
    }
    
    func prepareRequest() -> NSFetchRequest<NSFetchRequestResult> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Painting")
        let idString = chosenPaintingId?.uuidString
        fetchRequest.predicate = NSPredicate(format: "id = %@", idString!)
        fetchRequest.returnsObjectsAsFaults = false
        return fetchRequest
    }
    
    func setDataToControls(result: [NSFetchRequestResult]) {
        for res in result as! [NSManagedObject] {
            if let name = res.value(forKey: "name") as? String {
                nameText.text = name
            }
            
            if let year = res.value(forKey: "year") as? Int {
                yearText.text = String(year)
            }
            
            if let artist = res.value(forKey: "artist") as? String {
                artistText.text = artist
            }
            
            if let image = res.value(forKey: "image") as? Data {
                let imageData = UIImage(data: image)
                imageView.image = imageData
            }
        }
    }
    
    
    
}
