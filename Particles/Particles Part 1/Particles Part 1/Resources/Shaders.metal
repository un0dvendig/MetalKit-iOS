//
//  Shaders.metal
//  Particles Part 1
//
//  Created by Eugene Ilyin on 18.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Objects

struct Particle {
    float2 center;
    float radius;
    
    Particle(float2 c, float r) {
        center = c;
        radius = r;
    }
};

// MARK: - Functions

float distanceToParticle(float2 point, Particle p) {
    return length(point - p.center) - p.radius;
}

// MARK: - Compute

kernel void compute(texture2d<float, access::write> output [[ texture(0) ]],
                    constant float &timer [[ buffer(1) ]],
                    constant float2 &touch [[ buffer(2) ]],
                    uint2 gid [[ thread_position_in_grid ]]) {
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) {
        return;
    }
    int width = output.get_width();
    int height = output.get_height();
    
    float2 uv = float2(gid) / float2(width, height);

    float aspect = width / height;
    
    float2 center = float2(aspect / 2, timer);
    float radius = .05;
    
    float stop;
    /// iOS workaround for scaling
    if (width > height) {
        uv.x *= aspect;
        stop = 1 - radius;
    } else {
        uv.x -= .5;
        uv.y /= .5;
        stop = 2 * 1 - radius;
    }
    
    if (timer >= stop) {
        center.y = stop;
    } else {
        center.y = timer;
    }
    
    Particle p = Particle(center, radius);
    
    float distance = distanceToParticle(uv, p);
    float4 color = float4(1., .7, 0., 1.);
    if (distance > 0) {
        color = float4(.2, .5, .7, 1.);
    }
    
    output.write(color, gid);
}

