//
//  Shaders.metal
//  Introducing to Compute
//
//  Created by Eugene Ilyin on 27.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Compute

kernel void compute(texture2d<float, access::read> input [[texture(0)]],
                    texture2d<float, access::write> output [[texture(1)]],
                    uint2 id [[thread_position_in_grid]]) {
    if (id.x >= output.get_width() || id.y >= output.get_height()) {
        return;
    }
    
    /// Uncomment this and comment others to change RGB to GRB
//    float4 color = input.read(id);
//    color = float4(color.g, color.b, color.r, 1.0);
    
    ///   Uncomment this and comment other to apply grayscale
//    float4 color = input.read(id);
//    color.xyz = (color.r * 0.3 + color.g * 0.6 + color.b * 0.1) * 1.5;
    
    ///   Uncomment this and comment other to pixelate the image into n-px squares
    int n = 5;
    uint2 index = uint2((id.x / n) * n,
                        (id.y / n) * n);
    float4 color = input.read(index);
    
    output.write(color, id);
}
