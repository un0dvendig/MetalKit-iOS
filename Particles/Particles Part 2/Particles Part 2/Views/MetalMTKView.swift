//
//  MetalMTKView.swift
//  Particles Part 2
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import MetalKit

// FOR SOME REASON THIS PROJECT PRODUCES VISUAL BUG
// (RED LINE) ON THE SIDE OF THE SIMULATOR / REAL DEVICE
public class MetalMTKView: MTKView {
    
    // MARK: - Properties
    
    var commandQueue: MTLCommandQueue!
    var model: MTKMesh!
    var particles: [Particle]!
    var particlesBuffer: MTLBuffer!
    var renderPipelineState: MTLRenderPipelineState!
    var timer: Float = 0
    
    // MARK: - Initialization
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.clearColor = MTLClearColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        guard let queue = device.makeCommandQueue() else { return }
        self.commandQueue = queue
        
        createBuffers(for: device)
        registerShaders(for: device)
    }

    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        update()
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let descriptor = currentRenderPassDescriptor,
              let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let drawable = currentDrawable else { fatalError() }
        let submesh = model.submeshes[0]
        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
        renderCommandEncoder.setVertexBuffer(model.vertexBuffers[0].buffer, offset: 0, index: 0)
        renderCommandEncoder.setVertexBuffer(particlesBuffer, offset: 0, index: 1)
        renderCommandEncoder.drawIndexedPrimitives(type: .triangle, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: 0, instanceCount: particles.count)
        renderCommandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: - Private methods
    
    private func createBuffers(for device: MTLDevice) {
        particles = [Particle](repeating: Particle(), count: 1000)
        
        guard let particlesBuffer = device.makeBuffer(length: particles.count * MemoryLayout<Particle>.stride,
                                                      options: []) else {
                                                        fatalError("Cannot craete MTLBuffer")
        }
        self.particlesBuffer = particlesBuffer
        
        var pointer = particlesBuffer.contents().bindMemory(to: Particle.self,
                                                            capacity: particles.count)
        
        for _ in particles {
            /// We divide `x` coordinate by `10` to gather particles inside a small horizontal range,
            /// while we multiply `y` coordinate by `10` for the opposite effect.
            pointer.pointee.initialMatrix = translate(by: [Float(drand48()) / 10,
                                                           Float(drand48()) * 10,
                                                           0])
            pointer.pointee.color = SIMD4<Float>(0.2, 0.6, 0.9, 1)
            pointer = pointer.advanced(by: 1)
        }
        
        let allocator = MTKMeshBufferAllocator(device: device)
        let sphere = MDLMesh(sphereWithExtent: [0.01, 0.01, 0.01],
                             segments: [8, 8],
                             inwardNormals: false,
                             geometryType: .triangles,
                             allocator: allocator)
        
        do {
            model = try MTKMesh(mesh: sphere, device: device)
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    private func registerShaders(for device: MTLDevice) {
        do {
            guard let library = device.makeDefaultLibrary() else { return }
            
            let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            renderPipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")
            renderPipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
            renderPipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(model.vertexDescriptor)

            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func update() {
        timer += 0.01
        var pointer = particlesBuffer.contents().bindMemory(to: Particle.self,
                                                            capacity: particles.count)
        for _ in particles {
            pointer.pointee.matrix = translate(by: [0, -3 * timer, 0]) * pointer.pointee.initialMatrix
            pointer = pointer.advanced(by: 1)
        }
        
    }
}
