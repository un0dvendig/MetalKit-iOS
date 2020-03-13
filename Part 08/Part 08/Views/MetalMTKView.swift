//
//  MetalMTKView.swift
//  Part 08
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import MetalKit

public class MetalMTKView: MTKView {
    
    // MARK: - Properties
    
    var vertexBuffer: MTLBuffer!
    var renderPipelineState: MTLRenderPipelineState!
    var uniformBuffer: MTLBuffer!
    
    // MARK: - Initialization
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        createBuffers(for: device)
        registerShaders(for: device)
    }
    
    override public init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        
        guard let device = device else { return }
        createBuffers(for: device)
        registerShaders(for: device)
    }
    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let device = device else { return }
        
        guard let renderPassDescriptor = currentRenderPassDescriptor,
            let drawable = currentDrawable else {
                return
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        
        guard let commandBuffer = device.makeCommandQueue()?.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
        }
        
        commandEncoder.setRenderPipelineState(renderPipelineState)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)

        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: - Private methods
    
    private func createBuffers(for device: MTLDevice) {
        let vertexData = [
            Vertex(position: [-1.0, -1.0, 0.0, 1.0], color: [1, 0, 0, 1]),
            Vertex(position: [ 1.0, -1.0, 0.0, 1.0], color: [0, 1, 0, 1]),
            Vertex(position: [ 0.0,  1.0, 0.0, 1.0], color: [0, 0, 1, 1])
        ]
        // Alternatively use vertexData.count * MemoryLayout<Vertex>.size
        let vertexDataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexDataSize, options: [])
        
        let floatMatrixSize = MemoryLayout<Float>.size * 16 // Memory to hold 4x4 matrix
        uniformBuffer = device.makeBuffer(length: floatMatrixSize, options: [])
        let uniformBufferPointer = uniformBuffer.contents()
        let modelMatrix = Matrix().modelMatrix(matrix: Matrix()).m
        
        // TODO: Find more 'Swifty' way to deal with pointers instead of using `memcpy`
        // memcpy(uniformBufferPointer, modelMatrix, floatMatrixSize)
        uniformBufferPointer.copyMemory(from: modelMatrix, byteCount: floatMatrixSize) // possible solution?
    }
    
    private func registerShaders(for device: MTLDevice) {
        do {
            guard let library = device.makeDefaultLibrary() else { return }
            
            let vertexFunction = library.makeFunction(name: "vertex_func")
            let fragmentFunction = library.makeFunction(name: "fragment_func")
            
            let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineDescriptor.vertexFunction = vertexFunction
            renderPipelineDescriptor.fragmentFunction = fragmentFunction
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print(error.localizedDescription)
        }
    }
}
