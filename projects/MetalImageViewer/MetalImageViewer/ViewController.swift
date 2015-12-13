//
//  ViewController.swift
//  MetalImageViewer
//
//  Created by Yankang Chen on 12/13/15.
//  Copyright © 2015 Henry Chen. All rights reserved.
//

import UIKit
import Metal

class ViewController: UIViewController {
    
    // MARK: Properties
    
    // Constants
    let imageName = "Lena"
    
    // IBOutlets
    @IBOutlet weak var metalImageView: MetalImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get the default Metal device and create a new command queue
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            let metalCommandQueue = metalDevice.newCommandQueue()
            
            // Assign device and command queue to view
            metalImageView.device = metalDevice
            metalImageView.commandQueue = metalCommandQueue
            
            // Load image
            if let image = UIImage(named: imageName) {
                metalImageView.loadUIImage(image)
            } else {
                print("[ERROR] - Failed to read the image named \(imageName).")
            }
        } else {
            print("[ERROR] - No available Metal device.")
        }
    }

}

