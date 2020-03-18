//
//  MetalMTKView.swift
//  Memory Part 2
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import MetalKit
import ModelIO

public class MetalMTKView: MTKView {
    
    // MARK: - Properties
    
    enum Constant {
        static let count = 2000
    }
    
    let length = Constant.count * MemoryLayout< Float >.stride
    
    // MARK: - Initialization
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError() }
        self.device = device
        
        makeBufferLengthTest(for: device)
        makeBufferBytesTest(for: device)
//        makeBufferBytesNoCopyTest(for: device)
    }

    
    // MARK: - MTKView methods
    
    override public func draw(_ rect: CGRect) {
        
    }
    
    // MARK: - Private methods
    
    private func makeBufferLengthTest(for device: MTLDevice) {
        guard let myBuffer = device.makeBuffer(length: length,
                                               options: []) else { return }
        print("makeBuffer(lenght:options:)")
        print(myBuffer.contents())
        print()
    }
    
    private func makeBufferBytesTest(for device: MTLDevice) {
        var myVector = [Float](repeating: 0,
                               count: Constant.count)
        guard let myBuffer = device.makeBuffer(bytes: myVector,
                                               length: length,
                                               options: []) else { return }
        print("makeBuffer(bytes:lenght:options:)")
        withUnsafePointer(to: &myVector) {
            print($0)
        }
        print(myBuffer.contents())
        print()
    }
    
    private func makeBufferBytesNoCopyTest(for device: MTLDevice) {
        var memory: UnsafeMutableRawPointer?
        let alignment = 0x1000
        let allocationSize = (length + alignment - 1) & (~(alignment - 1))
        posix_memalign(&memory, alignment, allocationSize)
        
        /// `NOTE:` Crashes the app!
        let myBuffer = device.makeBuffer(bytesNoCopy: memory!,
                                         length: allocationSize,
                                         options: [],
                                         deallocator: { (pointer: UnsafeMutableRawPointer, _: Int) in
                                            free(pointer)
                                        })
        
        guard myBuffer != nil else { return }
        print("makeBuffer(bytesNoCopy:lenght:options:deallocator:)")
        print(memory!)
        print(myBuffer!.contents())
    }
}
