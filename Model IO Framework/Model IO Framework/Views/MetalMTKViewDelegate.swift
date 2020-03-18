//
//  MetalMTKViewDelegate.swift
//  Part 16-17
//
//  Created by Eugene Ilyin on 18.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import MetalKit
import simd
import ModelIO

public class MetalMTKView: MTKView {
    
    // MARK: - Properties
    
    var commandQueue: MTLCommandQueue!
    var renderPipelineState: MTLRenderPipelineState!
    var uniformBuffer: MTLBuffer!
    var vertexDescriptor: MTLVertexDescriptor!
    
    /// Additional properties
    var asset: MDLAsset!
    var commandBuffer: MTLCommandBuffer!
    var commandEncoder: MTLRenderCommandEncoder!
    var depthStencilState: MTLDepthStencilState!
    var meshes: (modelIOMeshes: [MDLMesh], metalKitMeshes: [MTKMesh])!
    var texture: MTLTexture!
    
    // MARK: - Initialization
    
    public required init(coder: NSCoder) {
        super.init(coder: coder)
        
        setupMTKView()
        setupMetal()
    }
    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        guard let drawable = self.currentDrawable,
            let renderPassDescriptor = self.currentRenderPassDescriptor else {
                fatalError("Resources are unavailable")
        }
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = self.clearColor
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            fatalError("Cannot create MTLCommandBuffer")
        }
        self.commandBuffer = commandBuffer
        
        guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            fatalError("Cannot create MTLRenderCommandEncoder")
        }
        self.commandEncoder = commandEncoder
        commandEncoder.setRenderPipelineState(renderPipelineState)
        commandEncoder.setDepthStencilState(depthStencilState)
        commandEncoder.setCullMode(.back)
        commandEncoder.setFrontFacing(.counterClockwise)
        commandEncoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)
        
        setupRenderingAndDrawing()
    }
    
    // MARK: - Private methods
    
    private func setupMTKView() {
        self.clearColor = MTLClearColor(red: 0.5,
                                        green: 0.5,
                                        blue: 0.5,
                                        alpha: 1)
        self.colorPixelFormat = .bgra8Unorm
        
        self.depthStencilPixelFormat = .depth32Float_stencil8
    }
    
    private func setupMetal() {
        /// Creating and assigning device
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Cannot create MTLDevice")
        }
        self.device = device
        
        /// Creating and assigning commandQueue
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Cannot create MTLCommandQueue")
        }
        self.commandQueue = commandQueue
        
        /// Creating and assigning depthStencilState
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        guard let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor) else {
            fatalError("Cannot create MTLDepthStencilState")
        }
        self.depthStencilState = depthStencilState
        
        /// Creating modelViewProjectionMatrix and buffers
        createBuffers(for: device)
        
        /// Creating library, shaders, renderPipelineState
        registerShaders(for: device)
        
        /// Creating assets
        setupAsset(for: device)
        
        /// Creating meshes and submesh objects
        setupMeshes(for: device)
    }
    
    private func createBuffers(for device: MTLDevice) {
        /// Creating modelViewProjectionMatrix
        let scaled = scalingMatrix(scale: 1)
        let rotated = rotationMatrix(angle: 90,
                                     axis: simd_float3(0, 1, 0))
        let translated = translationMatrix(position: simd_float3(0, -10, 0))
        let modelMatrix = matrix_multiply(matrix_multiply(translated,
                                                          rotated),
                                          scaled)
        
        let cameraPosition = simd_float3(0, 0, -100)
        let viewMatrix = translationMatrix(position: cameraPosition)
        
        let aspect = Float(self.drawableSize.width / self.drawableSize.height)
        let projMatrix = projectionMatrix(near: 0.1,
                                          far: 100,
                                          aspect: aspect,
                                          fovy: 1)
        
        let modelViewProjectionMatrix = matrix_multiply(projMatrix,
                                                        matrix_multiply(viewMatrix,
                                                                        modelMatrix))
        
        /// Creating MTLBuffer
        guard let uniformBuffer = device.makeBuffer(length: MemoryLayout.size(ofValue: modelViewProjectionMatrix),
                                                    options: []) else {
            fatalError("Cannot create MTLBuffer")
        }
        self.uniformBuffer = uniformBuffer
        
        
        /// Copying the matrix into the buffer
        let mvpMatrix = Uniforms(modelViewProjectionMatrix: modelViewProjectionMatrix)
        uniformBuffer.contents().storeBytes(of: mvpMatrix,
                                            toByteOffset: 0,
                                            as: Uniforms.self)
    }
    
    private func registerShaders(for device: MTLDevice) {
        /// Creating libraray
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Cannot create MTLLibrary")
        }
        
        /// Creating shaders
        guard let vertexFunction = library.makeFunction(name: "vertex_func"),
            let fragmentFunction = library.makeFunction(name: "fragment_func") else {
                fatalError("Cannot create shaders")
        }

//
//        Step 1: set up the render pipeline state
//
        self.vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].offset = 0 // position
        vertexDescriptor.attributes[0].format = .float3 // 4x3 bytes for vertex position
        
        vertexDescriptor.attributes[1].offset = 12 // color
        vertexDescriptor.attributes[1].format = .uchar4 // 4x1 bytes for vertex color
        
        vertexDescriptor.attributes[2].offset = 16 // texture
        vertexDescriptor.attributes[2].format = .half2 // 2x2 bytes for texture coordinates
        
        vertexDescriptor.attributes[3].offset = 20 // occlusion
        vertexDescriptor.attributes[3].format = .float // 4x1 bytes for ambient occlusion
        
        vertexDescriptor.layouts[0].stride = 24
        
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipelineDescriptor.depthAttachmentPixelFormat = self.depthStencilPixelFormat
        renderPipelineDescriptor.stencilAttachmentPixelFormat = self.depthStencilPixelFormat
        
        do {
            renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func setupAsset(for device: MTLDevice) {
//
//        Step 2: set up the asset initialization
//
        let modelIODescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
        
        var vertexAttribute = modelIODescriptor.attributes[0] as! MDLVertexAttribute
        vertexAttribute.name = MDLVertexAttributePosition
        
        vertexAttribute = modelIODescriptor.attributes[1] as! MDLVertexAttribute
        vertexAttribute.name = MDLVertexAttributeColor
        
        vertexAttribute = modelIODescriptor.attributes[2] as! MDLVertexAttribute
        vertexAttribute.name = MDLVertexAttributeTextureCoordinate
        
        vertexAttribute = modelIODescriptor.attributes[3] as! MDLVertexAttribute
        vertexAttribute.name = MDLVertexAttributeOcclusionValue
        
        let mtkBufferAllocator = MTKMeshBufferAllocator(device: device)
        guard let assetURL = Bundle.main.url(forResource: "Farmhouse",
                                             withExtension: "obj") else {
            fatalError("Cannot find asset file")
        }
        asset = MDLAsset(url: assetURL,
                         vertexDescriptor: modelIODescriptor,
                         bufferAllocator: mtkBufferAllocator)
        
        /// Loading the texture for the asset
        let loader = MTKTextureLoader(device: device)
        guard let textureFile = Bundle.main.url(forResource: "Farmhouse",
                                                withExtension: "png") else {
            fatalError("Cannot find texture file")
        }
        
        do {
            let data = try Data(contentsOf: textureFile)
            texture = try loader.newTexture(data: data,
                                            options: nil)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func setupMeshes(for device: MTLDevice) {
        guard let mesh = asset.object(at: 0) as? MDLMesh else {
            fatalError("Cannot find mesh")
        }
        mesh.generateAmbientOcclusionVertexColors(withQuality: 1,
                                                  attenuationFactor: 0.98,
                                                  objectsToConsider: [mesh],
                                                  vertexAttributeNamed: MDLVertexAttributeOcclusionValue)
        
        do {
            meshes = try MTKMesh.newMeshes(asset: asset, device: device)
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    private func setupRenderingAndDrawing() {
        guard let drawable = self.currentDrawable else {
            return
        }
        
        let metalKitMeshes = meshes.metalKitMeshes
        guard let mesh = metalKitMeshes.first else {
            fatalError("Cannot find the mesh")
        }
        let vertexBuffer = mesh.vertexBuffers[0]
        commandEncoder.setVertexBuffer(vertexBuffer.buffer,
                                       offset: vertexBuffer.offset,
                                       index: 0)
        
        guard let submesh = mesh.submeshes.first else {
            fatalError("Cannot find the submesh")
        }
        commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                             indexCount: submesh.indexCount,
                                             indexType: submesh.indexType,
                                             indexBuffer: submesh.indexBuffer.buffer,
                                             indexBufferOffset: submesh.indexBuffer.offset)
        commandEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

