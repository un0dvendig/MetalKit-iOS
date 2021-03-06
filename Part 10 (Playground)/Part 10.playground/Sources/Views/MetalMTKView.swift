//
//  MetalMTKView.swift
//  Part 10
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import MetalKit

public class MetalMTKView: MTKView {
    
    // MARK: - Properties
    
    var computePipelineState: MTLComputePipelineState!
    var queue: MTLCommandQueue!
    
    // MARK: - Initialization
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        guard let queue = device.makeCommandQueue() else { return }
        self.queue = queue
        
        registerShaders(for: device)
    }
    
    override public init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        
        guard let device = device else { return }
        guard let queue = device.makeCommandQueue() else { return }
        self.queue = queue
        
        registerShaders(for: device)
    }
    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        if let drawable = currentDrawable,
            let commandBuffer = queue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            commandEncoder.setComputePipelineState(computePipelineState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            
            let threadGroupCount = MTLSize(width: 8, height: 8, depth: 1)
            let threadGroups = MTLSize(width: drawable.texture.width / threadGroupCount.width,
                                       height: drawable.texture.height / threadGroupCount.height,
                                       depth: 1)
            
            commandEncoder.dispatchThreadgroups(threadGroups,
                                                threadsPerThreadgroup: threadGroupCount)
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
    
    // MARK: - Private methods
        
    private func registerShaders(for device: MTLDevice) {
        guard let path = Bundle.main.path(forResource: "Shaders", ofType: "metal") else { return }

        do {
            let inputString = try String(contentsOfFile: path, encoding: .utf8)            
            let library = try device.makeLibrary(source: inputString, options: nil)
            
            guard let kernel = library.makeFunction(name: "compute") else { return }
            computePipelineState = try device.makeComputePipelineState(function: kernel)
        } catch {
            print(error.localizedDescription)
        }
    }
}

