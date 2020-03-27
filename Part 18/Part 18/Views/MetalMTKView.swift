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
    
//    var shader: String = {
//        let string =
//        "#include <metal_stdlib>\n" +
//        "using namespace metal;" +
//        "kernel void k(texture2d<float, access::write> o[[ texture(0) ]]," +
//        "             uint2 gid [[ thread_position_in_grid ]]) {" +
//    "   if (gid.x >= o.get_width() || gid.y >= o.get_height()) {" +
//    "       return;" +
//    "   }" +
//        "   int width = o.get_width();" +
//        "   int height = o.get_height();" +
//        "   float2 uv = float2(gid) / float2(width, height);" +
//        "   float3 color = mix(float3(1.0, 0.6, 0.1)," +
//        "                      float3(0.5, 0.8, 1.0)," +
//        "                      sqrt(1 - uv.y));" +
//        "   float2 q = uv - float2(0.67, 0.25);" +
////      iOS workaround
//        "   if (width < height) {" +
//        "   q.y /= 0.5;" +
//        "   } else {" +
//        "   q.x /= 0.5;" +
//        "   }" +
//        "   float r = 0.2 + 0.1 * cos(atan2(q.x, q.y) * 9.0 + 20.0 * q.x + 1.0);" +
//        "   color *= smoothstep(r, r + 0.01, length(q));" +
//        "   r = 0.03 + 0.002 * cos(120.0 * q.y) + exp(-50.0 * (1.0 - uv.y));" +
//        "   color *= 1.0 - (1.0 - smoothstep(r, r + 0.002, abs(q.x - 0.25 * sin(2.0 * q.y)))) * " +
//        "   smoothstep(0.0, 0.1, q.y);" +
//        "   o.write(float4(color, 1.0), gid);" +
//        "}"
//
//        return string
//    }()
    
    var shader: String = {
        let string =
        "#include <metal_stdlib>\n" +
        "using namespace metal;" +
        "kernel void k(texture2d<float, access::write> o[[ texture(0) ]]," +
        "             uint2 gid [[ thread_position_in_grid ]]) {" +
        "   if (gid.x >= o.get_width() || gid.y >= o.get_height()) {" +
        "       return;" +
        "   }" +
        "   int width = o.get_width();" +
        "   int height = o.get_height();" +
        "   float2 uv = float2(gid) / float2(width, height);" +
        "   float2 q = uv - float2(.05);" +
//      iOS workaround
        "   if (width < height) {" +
        "   q.y /= 0.5;" +
        "   q.x -= 0.5;" +
        "   q.y -= 1.0;" +
        "   } else {" +
        "   q.x /= 0.5;" +
        "   q.x -= 1.0;" +
        "   q.y -= 0.5;" +
        "   }" +
        "   float a = atan2(q.y, q.x) + 0.25;" +
        "   float s = 0.5 + 0.5 * sin(3.0 * a);" +
        "   float t = 0.15 + 0.5 * pow(s, 0.3) + 0.1 * pow(0.5 + 0.5 * cos(6.0 * a), 0.5);" +
        "   float h = sqrt(dot(q,q)) / t;" +
        "   float f = 0.0;" +
        "   if(h < 0.4) f = 1.0;" +
        "   float3 color = mix(float3(0.9)," +
        "                      float3(0.5 * h, 0.5 + 0.5 * h, 0.0)," +
        "                      f);" +
        "   o.write(float4(color, 1.0), gid);" +
        "}"
        return string
    }()
    
    var commandQueue: MTLCommandQueue!
    var computePipelineState: MTLComputePipelineState!
    
    // MARK: - Initialization
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        self.device = device
        
        guard let queue = device.makeCommandQueue() else { return }
        self.commandQueue = queue
        
        let library = try! device.makeLibrary(source: shader, options: nil)
        let function = library.makeFunction(name: "k")!
        computePipelineState = try! device.makeComputePipelineState(function: function)
        
        self.framebufferOnly = false
    }
    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let device = self.device,
            let drawable = currentDrawable,
           let commandBuffer = commandQueue.makeCommandBuffer(),
           let commandEncoder = commandBuffer.makeComputeCommandEncoder() {
            commandEncoder.setComputePipelineState(computePipelineState)
            commandEncoder.setTexture(drawable.texture, index: 0)
            
            handleThreads(device: device, encoder: commandEncoder)
            
            commandEncoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
    
    // MARK: - Private methods
    
    private func handleThreads(device: MTLDevice, encoder commandEncoder: MTLComputeCommandEncoder) {
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
