//
//  ViewController.swift
//  Part 03
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet var mtkView: MTKView!
    
    // MARK: - Properties
    
    var vertexBuffer: MTLBuffer!
    var renderPipelineState: MTLRenderPipelineState! = nil
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setupMetalKit()
    }
    
    // MARK: - Private methods
    
    private func setupMetalKit() {
        mtkView.delegate = self
        
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        mtkView.device = device
        createBuffer(for: device)
        registerShaders(for: device)
    }
    
    private func render(in view: MTKView) {
        guard let device = view.device else { return }
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable else {
                return
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        
        guard let commandBuffer = device.makeCommandQueue()?.makeCommandBuffer(),
            let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
        }
        
        commandEncoder.setRenderPipelineState(renderPipelineState)
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
        
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func createBuffer(for device: MTLDevice) {
        let vertexData = [
            Vertex(position: [-1.0, -1.0, 0.0, 1.0], color: [1, 0, 0, 1]),
            Vertex(position: [ 1.0, -1.0, 0.0, 1.0], color: [0, 1, 0, 1]),
            Vertex(position: [ 0.0,  1.0, 0.0, 1.0], color: [0, 0, 1, 1])
        ]
        
        // Alternatively use vertexData.count * MemoryLayout<Vertex>.size
        let length = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: length, options: [])
    }
    
    private func registerShaders(for device: MTLDevice) {
        
        guard let library = device.makeDefaultLibrary(),
            let vertexFunction = library.makeFunction(name: "vertex_func"),
            let fragmentFunction = library.makeFunction(name: "fragment_func") else {
                return
        }
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
            
        } catch {
            print(error.localizedDescription)
        }
        
    }
}

// MARK: - MTKViewDelegate

extension ViewController: MTKViewDelegate {
    
    func draw(in view: MTKView) {
        render(in: view)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("mtkView(_:, drawableSizeWillChange:)")
    }
    
    
}
