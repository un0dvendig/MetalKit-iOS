//
//  Shaders.metal
//  Part 15
//
//  Created by Eugene Ilyin on 14.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void compute(texture2d<float, access::write> output [[ texture(0) ]],
                    texture2d<float, access::sample> input [[ texture(1) ]],
                    constant float &timer [[ buffer(0) ]],
                    uint2 gid [[ thread_position_in_grid ]]) {
    int width = input.get_width();
    int height = input.get_height();
    
    float2 uv = float2(gid) / float2(width, height);
    uv = uv * 2.0 - 1.0;
    
    /// Workaround for iOS devices to show planet in the center
    bool isWidth = output.get_width() < output.get_height();
    if (isWidth) {
        uv.y -= 1.25;
    } else {
        uv.x -= 1.25;
    }
    
    float radius = 0.5;
    float distance = length(uv) - radius;
    
    uv *= 2;
    radius = 1;
    constexpr sampler textureSampler(coord::normalized,
                                     address::repeat,
                                     min_filter::linear,
                                     mag_filter::linear,
                                     mip_filter::linear);
    float3 norm = float3(uv, sqrt(1.0 - dot(uv, uv)));
    float pi = 3.1415;
    float s = atan2(norm.z, norm.x) / (2 * pi);
    float t = asin(norm.y) / (2 * pi);
    t += 0.5;
    float4 color = input.sample(textureSampler, float2(s + timer * 0.1, t));
    
    output.write(distance < 0 ? color : float(0), gid);
}
