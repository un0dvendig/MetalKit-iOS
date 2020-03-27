//
//  Shaders.metal
//  Shadows Part 1
//
//  Created by Eugene Ilyin on 14.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Functions

/// Difference between two singed distances
float differenceOp(float d0, float d1) {
    return max(d0, -d1);
}

/// Determines if given point is either inside or outside of a rectangle
float distanceToRect(float2 point, float2 center, float2 size) {
    point -= center;
    point = abs(point);
    point -= size / 2.;
    return max(point.x , point.y);
}

/// Gives the closest distance to any object in the scene
float distanceToScene(float2 point) {
    float distToRay1 = distanceToRect(point,
                                float2(0.),
                                float2(.45, .85));
    float2 mod = point - .1 * floor(point / .1);
    float distToRay2 = distanceToRect(mod,
                                float2(.05),
                                float2(.02, .04));
    float diff = differenceOp(distToRay1, distToRay2);
    return diff;
}

/// Shadow function
float getShadow(float2 point, float2 lightPos) {
    float2 lightDir = normalize(lightPos - point);
    float distToLight = length(lightDir);
    float distAlongRay = 0.;
    for (float i = 0.; i < 80.; i++) {
        float2 currentPoint = point + lightDir * distAlongRay;
        float distToScene = distanceToScene(currentPoint);
        if (distToScene <= .001) {
            return 0.;
        }
        distAlongRay += distToScene;
        if (distAlongRay > distToLight) {
            break;
        }
    }
    return 1.;
}

// MARK: - Compute

kernel void compute(texture2d<float, access::write> output [[ texture(0) ]],
                    constant float &timer [[ buffer(0) ]],
                    uint2 gid [[ thread_position_in_grid ]]) {
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) {
        return;
    }
    int width = output.get_width();
    int height = output.get_height();
    
    float2 uv = float2(gid) / float2(width, height);
//    uv = uv * 2. - 1.;
    /// Use this to center the drawing
    uv.x -= .5;
    uv.y -= .5;
    
    /// Workaround for iOS devices
    if (width < height) {
        uv.y /= .5;
    } else {
        uv.x /= .5;
    }
    
    /// Scene
    float distToScene = distanceToScene(uv);
    bool i = distToScene < 0.;
    float4 color = i ? float4(.1, .5, .5, 1.) : float4(.7, .8, .8, 1.);
    
    /// Light
    float2 lightPos = float2(1.3 * sin(timer),
                             1.3 * cos(timer));
    float distToLight = length(lightPos - uv);
    color *= max(0., 2. - distToLight);
    
    /// Shadows
    float shadow = getShadow(uv, lightPos);
    shadow = shadow * .5 + .5;
    color *= shadow;
    
    output.write(color, gid);
}
