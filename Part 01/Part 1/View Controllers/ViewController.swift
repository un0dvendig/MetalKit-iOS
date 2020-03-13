//
//  ViewController.swift
//  Part 1
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet var mtkView: MTKView!
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView.delegate = self
    }
    
    // MARK: - Private methods
    
    private func render(in view: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        view.device = device
        
        guard let currentDrawable = view.currentDrawable else { return }
        
        let rpd = MTLRenderPassDescriptor()
        let bleen = MTLClearColor(red: 0, green: 0.5, blue: 0.5, alpha: 1)
        rpd.colorAttachments[0].texture = currentDrawable.texture
        rpd.colorAttachments[0].clearColor = bleen
        rpd.colorAttachments[0].loadAction = .clear
        
        guard let commandQueue = device.makeCommandQueue() else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else { return }
        
        encoder.endEncoding()
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }

}

// MARK: - MTKViewDelegate

extension ViewController: MTKViewDelegate {
    
    func draw(in view: MTKView) {
        render(in: view)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("mtkView(_:, drawableSizeWillChange:)")
    }
    
    
}

