//
//  ViewController.swift
//  Flower Snap
//
//  Created by Michael Zhou 
//  Copyright © 2019 Michael Zhou. All rights reserved.
//

// Import libraries
import UIKit        // Manages graphical, event driven UI
import CoreML       // Allows incorporating machine learning models into the app
import Vision       // Apply computer vision algorithms to classify input images
import Alamofire    // Allows the app to make HTTP GET requests
import SwiftyJSON   // Parses the JSON objects
import SDWebImage   // Provides an async image downloader with cache support to download images from URL link

// Sets up configuration of ViewController class
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // IB Outlets
    // Outlet for image view
    @IBOutlet weak var imageView: UIImageView!
    // Outlet for text label
    @IBOutlet weak var plantLabel: UILabel!
    
    // Global variables
    // Variable to hold the base URL of the Wikipedia API
    public let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    // Variable to hold the imagePicker object
    public let imagePicker = UIImagePickerController()
    
    // Initialisation method to set initial configuration when user launches the app
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set imagePicker delegate to itself
        imagePicker.delegate = self
        // Allows user to crop a selected image
        imagePicker.allowsEditing = true
        // Sets the camera as desired source type
        imagePicker.sourceType = .camera
    }
    
    // Method that manages the interface for taking pictures
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // Let the user pick cropped image
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
        // Convert cropped image into CIImage
        guard let CIImageConverted = CIImage(image: userPickedImage) else {
            // Unconditional error message prompt if image fails to convert
            fatalError("Cannot convert into CIImage.")
        }
        // Calls the detect method if conversion suceeds
        detect(image: CIImageConverted)
        // Selects image that user has picked
        imageView.image = userPickedImage
        }
        // Dismiss after user has finished picking image
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    // Method to process conversion of the model
    func detect(image: CIImage){
        // Create a Vision container for the model
        guard let model = try? VNCoreMLModel(for: FlowerSpotter().model) else {
            // Unconditional error message if the FlowerSpotter model fails to export
            fatalError("Cannot import model")
        }
        // Creates request to classify image
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify the image.")
            }
            // Outputs classification result in capitalised representation
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
        }
        
        // Creates handler to manage request
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            // Activate handler request
            try handler.perform([request])
            }
        catch {
            // Prints out error statement
            print(error)
        }
    }
    
    // Method to make HTTP GET requests in order to retrieve information from Wikipedia
    func requestInfo(flowerName: String) {
        // Array of dictionary items that will form as the parameters of the HTTP request
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]

        // Creates a request to retrieve contents from the specified parameters
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON
        {(response) in
            // If-else statement to check if the response request was successful
            if response.result.isSuccess {
                // Confirm if response was successful
                print("You have successfully retrieved the wikipedia info.")
                // Output response
                print(response)
    
                // Variable contains the parsed JSON object
                let flowerJSON : JSON = JSON(response.result.value!)
                // Variable holds page ID that serves as a key to access the extract
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                // Variable contains query to retrieve the information from extract
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                // Variable holds URL link to display image from the URL
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                // Replaces users image with display image from URL link
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                // Stores the result of the query from the flowerDescription variable
                self.plantLabel.text = flowerDescription
            }
        }
    }
    
    // Method to open the camera app
    @IBAction func cameraButtonTapped(_ sender: UIBarButtonItem) {
        // Transitions to in built camera upon tapping camera icon button
        present(imagePicker, animated: true, completion: nil)
    }
}

