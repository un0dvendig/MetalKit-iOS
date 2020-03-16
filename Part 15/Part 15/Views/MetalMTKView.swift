//
//  MetalMTKView.swift
//  Part 15
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import MetalKit

// FOR SOME REASON THIS PROJECT PRODUCES VISUAL BUG
// (RED LINE) ON THE SIDE OF THE SIMULATOR / REAL DEVICE
public class MetalMTKView: MTKView {
    
    // MARK: - Properties
    
    var computePipelineState: MTLComputePipelineState!
    var texture: MTLTexture!
    var timer: Float = 0
    var timerBuffer: MTLBuffer!
    var queue: MTLCommandQueue!
    
    // MARK: - Initialization
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        
        ///  `!IMPORTANT!`
        framebufferOnly = false
        
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        guard let queue = device.makeCommandQueue() else { return }
        self.queue = queue
        
        registerShaders(for: device)
        setupTexture(for: device)
    }

    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        if let drawable = currentDrawable,
            let commandBuffer = queue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            commandEncoder.setComputePipelineState(computePipelineState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            commandEncoder.setBuffer(timerBuffer, offset: 0, index: 0)
            commandEncoder.setTexture(texture, index: 1)
            update()
            
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
        do {
            guard let library = device.makeDefaultLibrary(),
                let kernel = library.makeFunction(name: "compute"),
                let timerBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: []) else {
                    return
                    
            }
            
            self.timerBuffer = timerBuffer
            computePipelineState = try device.makeComputePipelineState(function: kernel)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func update() {
        timer += 0.01
        let bufferPointer = timerBuffer.contents()
        bufferPointer.copyMemory(from: &timer, byteCount: MemoryLayout<Float>.size)
    }
    
    private func setupTexture(for device: MTLDevice) {
        guard let path = Bundle.main.path(forResource: "texture", ofType: "jpg") else {
            fatalError("Could not find texture.jpg")
        }
        
        let textureLoader = MTKTextureLoader(device: device)
        
        let fileURL = URL(fileURLWithPath: path)
        do {
            texture = try textureLoader.newTexture(URL: fileURL, options: nil)
        } catch {
            print(error.localizedDescription)
        }
    }
}
