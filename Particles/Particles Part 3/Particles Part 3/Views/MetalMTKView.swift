//
//  MetalMTKView.swift
//  Particles Part 3
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import MetalKit

// RUN THIS PROJECT ONLY ON DEVICES WITH A11 GPU AND LATER
public class MetalMTKView: MTKView {
    
    // MARK: - Properties
    
    var commandQueue: MTLCommandQueue!
    var firstRenderPipelineState: MTLComputePipelineState!
    var particlesBuffer: MTLBuffer!
    let particleCount = 10000
    var particles = [Particle]()
    var secondRenderPipelineState: MTLComputePipelineState!
    let side = 1200
    
    // MARK: - Initialization
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.framebufferOnly = false
        self.clearColor = MTLClearColor(red: 0.9,
                                        green: 0.9,
                                        blue: 0.9,
                                        alpha: 1)
        
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        guard let queue = device.makeCommandQueue() else { return }
        self.commandQueue = queue
        
        createBuffers(for: device)
        registerShaders(for: device)
    }

    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderCommandEncoder = commandBuffer.makeComputeCommandEncoder(),
              let drawable = currentDrawable else { fatalError() }

        // First pass
        renderCommandEncoder.setComputePipelineState(firstRenderPipelineState)
        renderCommandEncoder.setTexture(drawable.texture,
                                        index: 0)
        let w = firstRenderPipelineState.threadExecutionWidth
        let h = firstRenderPipelineState.maxTotalThreadsPerThreadgroup / w
        let threadsPerGroup = MTLSize(width: w,
                                      height: h,
                                      depth: 1)
        var threadPerGrid = MTLSize(width: side,
                                    height: side,
                                    depth: 1)
        
        renderCommandEncoder.dispatchThreads(threadPerGrid,
                                             threadsPerThreadgroup: threadsPerGroup)
        
        // Second pass
        renderCommandEncoder.setComputePipelineState(secondRenderPipelineState)
        renderCommandEncoder.setTexture(drawable.texture, index: 0)
        renderCommandEncoder.setBuffer(particlesBuffer, offset: 0, index: 0)
        threadPerGrid = MTLSize(width: particleCount,
                                height: 1,
                                depth: 1)
        renderCommandEncoder.dispatchThreads(threadPerGrid,
                                             threadsPerThreadgroup: threadsPerGroup)
        renderCommandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: - Private methods
    
    private func createBuffers(for device: MTLDevice) {
        for _ in 0 ..< particleCount {
            let particle = Particle(position: SIMD2<Float>(Float(arc4random() % UInt32(side)),
                                                           Float(arc4random() % UInt32(side))),
                                    velocity: SIMD2<Float>((Float(arc4random() % 10) - 5) / 10,
                                                           (Float(arc4random() % 10) - 5) / 10))
            particles.append(particle)
        }
        let size = particles.count * MemoryLayout<Particle>.size
        
        guard let particlesBuffer = device.makeBuffer(bytes: &particles,
                                                      length: size,
                                                      options: []) else {
                                                        fatalError("Cannot create MTLBuffer")
        }
        self.particlesBuffer = particlesBuffer
        
    }
    
    private func registerShaders(for device: MTLDevice) {
        do {
            guard let library = device.makeDefaultLibrary(),
                let firstPass = library.makeFunction(name: "firstPass"),
                let secondPass = library.makeFunction(name: "secondPass") else { return }
            firstRenderPipelineState = try device.makeComputePipelineState(function: firstPass)
            secondRenderPipelineState = try device.makeComputePipelineState(function: secondPass)
        } catch {
            print(error.localizedDescription)
        }
    }
}
