//
//  MetalMTKView.swift
//  Ambient Occlusion
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
    var touchBuffer: MTLBuffer!
    var pos: CGPoint!
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
    }

    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        if let drawable = currentDrawable,
            let commandBuffer = queue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            
            commandEncoder.setComputePipelineState(computePipelineState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            commandEncoder.setBuffer(timerBuffer, offset: 0, index: 1)
            commandEncoder.setBuffer(touchBuffer, offset: 0, index: 2)
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
    
    // MARK: - Touches
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        pos = touch.location(in: self)
        let scale = layer.contentsScale
        pos.x *= scale
        pos.y *= scale
    }
    
    // MARK: - Private methods
        
    private func registerShaders(for device: MTLDevice) {
        do {
            guard let library = device.makeDefaultLibrary(),
                let kernel = library.makeFunction(name: "compute"),
                let timerBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: []),
                let touchBuffer = device.makeBuffer(length: MemoryLayout<CGPoint>.size, options: []) else {
                    return
                    
            }
            
            self.timerBuffer = timerBuffer
            self.touchBuffer = touchBuffer
            computePipelineState = try device.makeComputePipelineState(function: kernel)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func update() {
        timer += 0.01
        var bufferPointer = timerBuffer.contents()
        bufferPointer.copyMemory(from: &timer, byteCount: MemoryLayout<Float>.size)
        
        bufferPointer = touchBuffer.contents()
        bufferPointer.copyMemory(from: &pos, byteCount: MemoryLayout<CGPoint>.size)
    }
}
