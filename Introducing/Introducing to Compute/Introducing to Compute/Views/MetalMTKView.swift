//
//  MetalMTKView.swift
//  Introducing to Compute
//
//  Created by Eugene Ilyin on 27.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import MetalKit

public class MetalMTKView: MTKView {
    
    // MARK: - Properties
    
    private var commandQueue: MTLCommandQueue?
    private var computePipelineState: MTLComputePipelineState?
    private var image: MTLTexture?
    
    // MARK: - Initialization
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.framebufferOnly = false
        guard let device = MTLCreateSystemDefaultDevice() else {
            return
        }
        self.device = device
        setupMetal(for: device)
    }
    
    override public init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        
        self.framebufferOnly = false
        guard let device = device else {
            return
        }
        setupMetal(for: device)
    }
    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let device = device,
            let commandQueue = commandQueue,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder(),
            let computePipelineState = computePipelineState,
            let image = image,
            let currentDrawable = currentDrawable else {
            return
        }
        
        
        commandEncoder.setComputePipelineState(computePipelineState)
        commandEncoder.setTexture(image, index: 0)
        commandEncoder.setTexture(currentDrawable.texture, index: 1)
        

        /// gridSize = groupsPerGrid * threadsPerThreadgroup [threadsPerGrid]
        /// On iOS:
        /// theardsPerGroup.width x theardsPerGroup.height x theardsPerGroup.depth
        /// `SHOULD` be less or equal to `512`
        
        // threadsPerThreadgroup
        let threadWidth = computePipelineState.threadExecutionWidth
        let threadHeight = computePipelineState.maxTotalThreadsPerThreadgroup / threadWidth
        let threadsPerThreadgroup = MTLSizeMake(threadWidth, threadHeight, 1)
        
        // threadgroupsPerGrid / threadsPerGrid
        if #available(iOS 11.0, *) {
            dispatchThreads(device: device,
                            commandEncoder: commandEncoder,
                            threadsPerThreadgroup: threadsPerThreadgroup)
        } else {
            dispatchThreadgroups(commandEncoder: commandEncoder,
                                 threadsPerThreadgroup: threadsPerThreadgroup)
        }
        
        commandEncoder.endEncoding()
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
    // MARK: - Private methods
    
    private func setupMetal(for device: MTLDevice) {
        guard let commandQueue = device.makeCommandQueue() else {
            return
        }
        self.commandQueue = commandQueue
        
        let textureLoader = MTKTextureLoader(device: device)
        
        guard let imageURL = Bundle.main.url(forResource: "nature", withExtension: "jpg") else {
            return
        }
        
        do {
            guard let library = device.makeDefaultLibrary() else {
                return
            }
            
            guard let computeFunction = library.makeFunction(name: "compute") else {
                return
            }
            
            computePipelineState = try device.makeComputePipelineState(function: computeFunction)
            image = try textureLoader.newTexture(URL: imageURL, options: [:])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @available(iOS 11.0, *)
    private func dispatchThreads(device: MTLDevice, commandEncoder: MTLComputeCommandEncoder, threadsPerThreadgroup: MTLSize) {
        
        if device.supportsFeatureSet(.iOS_GPUFamily4_v1) {
            let drawableWidth = Int(drawableSize.width)
            let drawableHeight = Int(drawableSize.height)
            let threadsPerGrid = MTLSize(width: drawableWidth,
                                    height: drawableHeight,
                                    depth: 1)
        
            commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        } else {
            dispatchThreadgroups(commandEncoder: commandEncoder,
                                 threadsPerThreadgroup: threadsPerThreadgroup)
        }
    }
    
    private func dispatchThreadgroups(commandEncoder: MTLComputeCommandEncoder, threadsPerThreadgroup: MTLSize) {
        let drawableWidth = Int(drawableSize.width)
        let drawableHeight = Int(drawableSize.height)
        let w = threadsPerThreadgroup.width
        let h = threadsPerThreadgroup.height
        let threadgroupsPerGrid = MTLSize(width: (drawableWidth + w - 1) / w,
                                    height: (drawableHeight + h - 1) / h,
                                    depth: 1)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }
    
}
