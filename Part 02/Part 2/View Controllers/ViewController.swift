//
//  ViewController.swift
//  Part 2
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet var mtkView: MTKView!
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mtkView.delegate = self
    }
    
    // MARK: - Private methods
    
    private func render(in view: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        view.device = device
        
        let vertexData: [Float] = [
            -1.0, -1.0, 0.0, 1.0,
             1.0, -1.0, 0.0, 1.0,
             0.0,  1.0, 0.0, 1.0
        ]
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        guard let vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: []),
            let library = device.makeDefaultLibrary(),
            let vertexFunction = library.makeFunction(name: "vertex_func"),
            let fragmentFunction = library.makeFunction(name: "fragment_func") else {
            return
        }
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        let renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable else {
                return
        }
        
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0.5, blue: 0.5, alpha: 1)
        
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