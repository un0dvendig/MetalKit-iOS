//
//  Shaders.metal
//  Part 10
//
//  Created by Eugene Ilyin on 14.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// Distance function

float dist(float2 point, float2 center, float radius) {
    return length(point - center) - radius;
}

kernel void compute(texture2d<float, access::write> output [[ texture(0) ]],
                    uint2 gid [[ thread_position_in_grid ]]) {
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) {
        return;
    }
    
    int width = output.get_width();
    int height = output.get_height();
    
    float2 uv = float2(gid) / float2(width, height);
    uv = uv * 2.0 - 1.0;
    
    // iOS workaround
    if (width > height) {
        uv.x /= .5;
    } else {
        uv.y /= .5;
    }
    
    float distToCircle = dist(uv, float2(0), 0.5);
    float distToCircle2 = dist(uv, float2(-0.1, 0.1), 0.5);
    bool inside = distToCircle2 < 0;
    
    output.write(inside ? float4(0) : float4( 1, 0.7, 0, 1) * (1 - distToCircle), gid);
}
