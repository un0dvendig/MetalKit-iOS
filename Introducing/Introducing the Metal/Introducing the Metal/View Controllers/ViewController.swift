//
//  ViewController.swift
//  Introducing the Metal
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import MetalKit
import UIKit

class ViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var label: UILabel!
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetalKit()
    }
    
    // MARK: - Private methods
    
    private func setupMetalKit() {
        let device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            label.text = "Your GPU does not support Metal!"
            return
        }
        label.text = "Your system has the following GPU:\n"
        label.text? += device!.name
    }

}

