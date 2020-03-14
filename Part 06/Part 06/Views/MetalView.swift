//
//  MetalView.swift
//  Part 6
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import UIKit

// FOR SOME REASON THIS PROJECT DOES NOT WORK PROPERLY
// NEITHER ON SIMULATOR NOR ON REAL DEVICE
// 
// IN ORDER TO TEST PROJECT IN SIMULATOR UNCOMMENT NEXT LINE
// @available(iOS 13.0, *)
class MetalView: UIView {
    
    // MARK: - Properties
    
    var commandQueue: MTLCommandQueue!
    var metalLayer: CAMetalLayer!
    
    // MARK: - UIView methods
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        metalLayer = CAMetalLayer()
        metalLayer.device = MTLCreateSystemDefaultDevice()
        metalLayer.frame = layer.frame
        layer.addSublayer(metalLayer)
        commandQueue = metalLayer.device?.makeCommandQueue()
        redraw()
    }
    
    // MARK: - Methods
    
    private func redraw() {
        guard let drawable = metalLayer.nextDrawable() else { return }
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0.5, blue: 0.5, alpha: 1)
        descriptor.colorAttachments[0].texture = drawable.texture
        
        if let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) {
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
