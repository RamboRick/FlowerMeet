//
//  ViewController.swift
//  FlowerMeet
//
//  Created by Fanghao Song on 3/7/18.
//  Copyright © 2018 Fanghao Song. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURL = "http://en.wikipedia.org/w/api/php"
    let imagePicker = UIImagePickerController()

    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var Label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
        
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let userPickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
        
            guard let convertedCIImage = CIImage(image: userPickedImage) else{
                fatalError("cannot convert to a CIImage ")
            }
        detect(image: convertedCIImage)
       
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        }
    

        
    func detect(image: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{
            fatalError("Can not import model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image.")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
        try handler.perform([request])
        }
        
        catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String){
        
        let parameters : [String : String] = [
            
            "format" : "json",
            "action" : "query",
            "prop" : "extracts |pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print ("Got the wilipedia info")
                print(response)
                
                let flowerJSON :JSON = JSON(response.result.value!)
                
                let pageid = flowerJSON["query"]["pageid"][0].stringValue
                
                let flowerDiscription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].url
                
                self.imageView.sd_setImage(with: flowerImageURL)
                
                self.Label.text = flowerDiscription
                
            }
        }
    }
    

    @IBAction func CameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
}

