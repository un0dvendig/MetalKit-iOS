//
//  Shaders.metal
//  Raymarching
//
//  Created by Eugene Ilyin on 14.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

//  MARK: - Objects

struct Ray {
    float3 origin;
    float3 direction;
    
    Ray(float3 o, float3 d) {
        origin = o;
        direction = d;
    }
};

struct Sphere {
    float3 center;
    float radius;
    
    Sphere(float3 c, float r) {
        center = c;
        radius = r;
    }
};

// MARK: - Distance functions

float dist(float2 point, float2 center, float radius) {
    return length(point - center) - radius;
}

float distToSphere(Ray ray, Sphere sphere) {
    return length(ray.origin - sphere.center) - sphere.radius;
}

float distToScene(Ray ray) {
    Sphere sphere = Sphere(float3(1.), 0.5);
    Ray repeatRay = ray;
    repeatRay.origin = fmod(ray.origin, 2.);
    return distToSphere(repeatRay, sphere);
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
    uv = uv * 2. - 1.;
    
    // iOS workaround
    if (width > height) {
        uv.x /= .5;
    } else {
        uv.y /= .5;
    }
    
    
    float3 camPos = float3(1000. + sin(timer) + 1.,
                           1000. + cos(timer) + 1.,
                           timer);
    Ray ray = Ray(camPos,
                  normalize(float3(uv, 1.0)));
    float3 color = float3(0.);
    // Increase max `i` to increase output image quality
    for (int i = 0; i < 100.; i++) {
        float dist = distToScene(ray);
        if (dist < .001) {
            color = float3(1.);
            break;
        }
        ray.origin += ray.direction * dist;
    }
    
    float3 posRelativeToCamera = ray.origin - camPos;
    
    output.write(float4(color * abs(posRelativeToCamera / 10. ), 1.), gid);
}
