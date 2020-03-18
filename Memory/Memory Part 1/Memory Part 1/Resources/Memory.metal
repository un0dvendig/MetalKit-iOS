//
//  Memory.metal
//  Memory Part 1
//
//  Created by Eugene Ilyin on 18.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Compute

#include <metal_stdlib>
using namespace metal;

kernel void compute(const device float *inVector [[ buffer(0) ]],
                    device float *outVector [[ buffer(1) ]],
                    uint id [[ thread_position_in_grid ]]) {
    outVector[id] = 1.0 / (1.0 + exp(-inVector[id]));
}
