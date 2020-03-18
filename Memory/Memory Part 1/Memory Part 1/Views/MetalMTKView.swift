//
//  MetalMTKView.swift
//  Memory Part 1
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import MetalKit
import ModelIO

public class MetalMTKView: MTKView {
    
    // MARK: - Properties
    
    var commandBuffer: MTLCommandBuffer!
    var commandEncoder: MTLComputeCommandEncoder!
    
    // MARK: - Initialization
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError() }
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue(),
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeComputeCommandEncoder() else { fatalError() }
        self.commandBuffer = commandBuffer
        self.commandEncoder = commandEncoder
        
        makeBufferTest(for: device)
        makeModelIOTest()
    }

    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        
    }
    
    // MARK: - Private methods
    
    private func makeBufferTest(for device: MTLDevice) {
        let count = 512
        
        var myVector = [Float](repeating: 0, count: count)
        let length = count * MemoryLayout<Float>.stride
        
        /// *makeBuffer(lenght:options:)*
        /// creates a `MTLBuffer` object with new allocation
        ///
        /// *makeBuffer(bytes:lenght:options:)*
        /// copies data from an existing allocation into new allocation
        ///
        /// *makeBuffer(bytesNoCopy:lenght:options:deallocator:)*
        /// reuses an axisting storage allocation
        guard let outBuffer = device.makeBuffer(bytes: myVector,
                                                length: length,
                                                options: []) else { fatalError() }
        
        for (index, _) in myVector.enumerated() {
            myVector[index] = Float(index)
        }
        
        guard let inBuffer = device.makeBuffer(bytes: myVector,
                                               length: length,
                                               options: []) else { fatalError() }
        
        guard let library = device.makeDefaultLibrary(),
            let function = library.makeFunction(name: "compute") else { fatalError() }
        
        do {
            let computePipelineState = try device.makeComputePipelineState(function: function)
            commandEncoder.setComputePipelineState(computePipelineState)
        } catch {
            print(error.localizedDescription)
        }
        
        /// `Note:` the Metal Best Practices Guide states that we should always avoid creating buffers when our
        /// data is less than `4KB` (up to a thousand `Floats`, e.g.). In this case we should simply use the
        /// `setBytes()` function instead of creating a buffer.
        commandEncoder.setBuffer(inBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(outBuffer, offset: 0, index: 1)
    
        let size = MTLSize(width: count, height: 1, depth: 1)
        commandEncoder.dispatchThreadgroups(size, threadsPerThreadgroup: size)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        
        /// Reading the data the `GPU` sent back by using the `contents()` function
        /// to bind the memory data to out output buffer.
        let result = outBuffer.contents().bindMemory(to: Float.self, capacity: count)
        var data = [Float](repeating: 0, count: count)
        for i in 0 ..< count {
            data[i] = result[i]
        }
    }
    
    private func makeModelIOTest() {
        guard let url = Bundle.main.url(forResource: "teapot", withExtension: "obj") else { fatalError() }
        
        let asset = MDLAsset(url: url)
        let voxelArray = MDLVoxelArray(asset: asset, divisions: 10, patchRadius: 0)
        
        if let data = voxelArray.voxelIndices() {
            data.withUnsafeBytes { (voxels: UnsafePointer<MDLVoxelIndex>) in
                let count = data.count / MemoryLayout<MDLVoxelIndex>.size
                
                var voxelIndex = voxels
                for _ in 0 ..< count {
                    let position = voxelArray.spatialLocation(ofIndex: voxelIndex.pointee)
                    print(position)
                    voxelIndex = voxelIndex.successor()
                }
            }
        }
    }
}
