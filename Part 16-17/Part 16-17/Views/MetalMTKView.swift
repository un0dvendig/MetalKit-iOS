//
//  MetalMTKView.swift
//  Part 04-05
//
//  Created by Eugene Ilyin on 14.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import MetalKit
import simd

public class MetalMTKView: MTKView {
    
    // MARK: - Properties
    
    var indexBuffer: MTLBuffer!
    var vertexBuffer: MTLBuffer!
    var renderPipelineState: MTLRenderPipelineState!
    var rotation: Float = 0
    var uniformBuffer: MTLBuffer!
    var queue: MTLCommandQueue!
    
    // MARK: - Initialization
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        
        guard let queue = device.makeCommandQueue() else { return }
        self.queue = queue
        
        createBuffers(for: device)
        registerShaders(for: device)
    }
    
    override public init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        
        guard let device = device else { return }
        guard let queue = device.makeCommandQueue() else { return }
        self.queue = queue
        
        createBuffers(for: device)
        registerShaders(for: device)
    }
    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        update()
        if let renderPassDescriptor = currentRenderPassDescriptor,
            let drawable = currentDrawable,
            let commandBuffer = queue.makeCommandBuffer() {

            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)

            guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }

            commandEncoder.setRenderPipelineState(renderPipelineState)

            commandEncoder.setFrontFacing(.counterClockwise)
//            commandEncoder.setCullMode(.back)

            commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)

            commandEncoder.setTriangleFillMode(.lines);
            commandEncoder.drawIndexedPrimitives(type: .triangle,
                                                 indexCount: indexBuffer.length / MemoryLayout<UInt16>.size,
                                                 indexType: .uint16,
                                                 indexBuffer: indexBuffer,
                                                 indexBufferOffset: 0)
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
            
    }
    
    // MARK: - Private methods
    
    private func createBuffers(for device: MTLDevice) {
        let vertexData = [
            Vertex(position: [-1.0, -1.0,  1.0, 1.0], color: [1, 0, 0, 1]),
            Vertex(position: [ 1.0, -1.0,  1.0, 1.0], color: [0, 1, 0, 1]),
            Vertex(position: [ 1.0,  1.0,  1.0, 1.0], color: [0, 0, 1, 1]),
            Vertex(position: [-1.0,  1.0,  1.0, 1.0], color: [1, 1, 1, 1]),
            Vertex(position: [-1.0, -1.0, -1.0, 1.0], color: [0, 0, 1, 1]),
            Vertex(position: [ 1.0, -1.0, -1.0, 1.0], color: [1, 1, 1, 1]),
            Vertex(position: [ 1.0,  1.0, -1.0, 1.0], color: [1, 0, 0, 1]),
            Vertex(position: [-1.0,  1.0, -1.0, 1.0], color: [0, 1, 0, 1])
        ]
        
        let indexData: [UInt16] = [
            0, 1, 2, 2, 3, 0,   // front
            1, 5, 6, 6, 2, 1,   // right
            3, 2, 6, 6, 7, 3,   // top
            4, 5, 1, 1, 0, 4,   // bottom
            4, 0, 3, 3, 7, 4,   // left
            7, 6, 5, 5, 4, 7,   // back
        ]
        
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: vertexData.count * MemoryLayout.size(ofValue: vertexData[0]),
                                         options: [])
        
        indexBuffer = device.makeBuffer(bytes: indexData,
                                        length: indexData.count * MemoryLayout.size(ofValue: indexData[0]),
                                        options: [])
        
        uniformBuffer = device.makeBuffer(length: MemoryLayout<matrix_float4x4>.size,
                                          options: [])
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
    
    private func update() {
        let scaled = scalingMatrix(scale: 0.5)
        rotation += 1 / 100 * .pi / 4
        
        let axisY = simd_float3(0, 1, 0)
        let axisX = simd_float3(1, 0, 0)
        
        let rotatedY = rotationMatrix(angle: rotation, axis: axisY)
        let rotatedX = rotationMatrix(angle: .pi / 4, axis: axisX)
        
        let rotated = matrix_multiply(rotatedX, rotatedY)
        let modelMatrix = matrix_multiply(rotated, scaled)
        
        let cameraPosition = simd_float3(0, 0, -3)
        
        /// Transform the pixel from `world space` to `camera space`
        let viewMatrix = translationMatrix(position: cameraPosition)
        
        /// Transform the pixel from `camera space` to `clip space`
        /// Here, all the vertices that are not insed the `clip space` will determine
        /// whether the triangle will be `culled` (all vertices outside the clip space)
        /// or `clipped to bounds` (some vertices are outside but not all)
        let aspect = Float(drawableSize.width / drawableSize.height)
        let projMatrix = projectionMatrix(near: 0, far: 10, aspect: aspect, fovy: 1)
     
        /// Transform the pixel from `clip space` to `normalized device coordinates(NDC)`
        let viewModelMatrix = matrix_multiply(viewMatrix, modelMatrix)
        
        /// Transform the pixel from `NDC` to `screen space`
        let modelViewPorjectionMatrix = matrix_multiply(projMatrix, viewModelMatrix)
        
        let uniformBufferPointer = uniformBuffer.contents()
        var uniforms = Uniforms(modelViewProjectionMatrix: modelViewPorjectionMatrix)
        let uniformsSize = MemoryLayout.size(ofValue: uniforms)
        
        uniformBufferPointer.copyMemory(from: &uniforms, byteCount: uniformsSize)
    }
}
