//
//  Shaders.metal
//  Part 13
//
//  Created by Eugene Ilyin on 14.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// Distance function

float distToCircle(float2 point, float2 center, float radius) {
    return length(point - center) - radius;
}

// Smothersstep function

float smootherstep(float e1, float e2, float x) {
    x = clamp((x - e1) / (e2 - e1), 0.0, 1.0);
    return x * x * x * (x * (x * 6 - 15) + 10);
}

// Random function

float random(float2 p) {
    return fract(sin(dot(p, float2(15.79, 81.93)) * 45678.9123));
}

// Noise function

float noise(float2 p) {
    /// Using `i` to move along grid points
    float2 i = floor(p);
    /// Using `f` as an offset between grid points
    float2 f = fract(p);
    /// Cubic Hermite Spline: 3f^2 - 2f^2
    /// Creates a S-shaped curve that values between [0; 1]
    f = f * f * (3.0 - 2.0 * f);
    //// Interpolate values along the bottom and the top of the grid
    float bottom = mix(random(i + float2(0)), random(i + float2(1.0, 0.0)), f.x);
    float top = mix(random(i + float2(0.0, 1.0)), random(i + float2(1)), f.x);
    //// Interpolate the vertical line between those 2 horizontal points to get final value for noise
    float t = mix(bottom, top, f.y);
    return t;
}

// Fractional Brownian Motion function

float fbm(float2 uv) {
    float sum = 0;
    float amp = 0.7;
    /// By adding various (four - in this case) `octaves` of this noise at different amplitudes,
    /// we can generage a simple cloud-like pattern
    for (int i = 0; i < 4; i++) {
        sum += noise(uv) * amp;
        uv += uv * 1.2;
        amp *= 0.4;
    }
    return sum;
}

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
    
    uv = uv * 2.0 - 1.0;
    
    /// Workaround for iOS devices to show circle
    bool isWidth = width < height;
    if (isWidth) {
        uv.y /= 0.5;
    } else {
        uv.x /= 0.5;
    }
    
    float radius = 0.5;
    float distance = distToCircle(uv, float2(0), radius);

    /// Equation for any point on a sphere:
    /// (x - x0)^2 + (y - y0)^2 + (z - z0)^2 = r^2
    /// x0, y0 and z0 are 0, since our `sphere` is in the center of the screen.
    /// Solving the equation for `z` gives us the value of the `planet` color.
//    float planet = float(sqrt(radius * radius - uv.x * uv.x - uv.y * uv.y));
////    planet /= radius;
////    output.write(distance < 0 ? float4(planet) : float4(0), gid);
    
    /// Lighting
    /// In order to have lights in the scene we need to compute the `normal` at each coordinate.
    /// Normals vectors that are perpendicular on the surface, showing us where the surface "point" to at each coordinate.
//    float3 normal = normalize(float3(uv.x, uv.y, planet));
////    output.write(distance < 0 ? float4(float3(normal), 1) : float4(0), gid);
////    float3 source = normalize(float3(-1, 0, 1));
//    float3 source = normalize(float3(cos(timer), sin(timer), 1));
//    float light = dot(normal, source);
//    output.write(distance < 0 ? float4(float3(light), 1) : float4(0), gid);
    
    /// Noise
    uv = fmod(uv + float2(timer * 0.2, 0), float2(width, height));
    float t = fbm(uv * 3);
    output.write(distance < 0 ? float4(float3(t), 1) : float4(0), gid);
}
