//
//  MetalMTKView.swift
//  Part 1
//
//  Created by Eugene Ilyin on 14.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import Foundation
import MetalKit

class MetalMTKView: MTKView {
    
    // MARK: - MTKView methods
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        render()
    }
    
    // MARK: - Private methods
    
    private func render() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        
        guard let currentDrawable = currentDrawable else { return }
        
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
