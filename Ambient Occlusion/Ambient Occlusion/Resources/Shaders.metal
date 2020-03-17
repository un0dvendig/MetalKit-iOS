//
//  Shaders.metal
//  Ambient Occlusion
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

struct Box {
    float3 center;
    float size;
    
    Box(float3 c, float s) {
        center = c;
        size = s;
    }
};

struct Plane {
    float yCoord;
    
    Plane(float y) {
        yCoord = y;
    }
};

struct Camera {
    float3 position;
    Ray ray = Ray(float3(0), float3(0));
    float rayDivergence;
    
    Camera(float3 pos, Ray r, float div) {
        position = pos;
        ray = r;
        rayDivergence = div;
    }
};

// MARK: - Distance functions

float unionOp(float distance0, float distance1) {
    return min(distance0, distance1);
}

float differenceOp(float distance0, float distance1) {
    return max(distance0, -distance1);
}

float distToSphere(Ray ray, Sphere sphere) {
    return length(ray.origin - sphere.center) - sphere.radius;
}

float distToBox(Ray ray, Box box) {
    float3 d = abs(ray.origin - box.center) - float3(box.size);
    return min(max(d.x, max(d.y, d.z)), 0.) + length(max(d, 0.));
}

float distToPlane(Ray ray, Plane plane) {
    return ray.origin.y - plane.yCoord;
}

/// Gives the closest distance to any object in the scene
float distToScene(Ray ray) {
    Plane plane = Plane(0.);
    float distanceToPlane = distToPlane(ray, plane);
    Sphere sphere0 = Sphere(float3(0., .5, 0.), 8.);
    Sphere sphere1 = Sphere(float3(0., .5, 0.), 6.);
    Sphere sphere2 = Sphere(float3(10., -4., -10.), 15.);
    Box box = Box(float3(1., 1., -4.), 1.);
    float distanceToBox = distToBox(ray, box);
    float distToSphere0 = distToSphere(ray, sphere0);
    float distToSphere1 = distToSphere(ray, sphere1);
    float distToSphere2 = distToSphere(ray, sphere2);
    float dist = differenceOp(distToSphere0, distToSphere1);
    dist = differenceOp(dist, distToSphere2);
    dist = unionOp(dist, distanceToBox);
    dist = unionOp(distanceToPlane, dist);
    return dist;
}

// MARK: - Other functions

float3 getNormal(Ray ray) {
    ///  Vector named `eps` is used to do `vector swizzling`
    float2 eps = float2(.001, 0.);
    float3 normal = float3(distToScene(Ray(ray.origin + eps.xyy,
                                           ray.direction)) -
                           distToScene(Ray(ray.origin - eps.xyy,
                                           ray.direction)),
                           
                           distToScene(Ray(ray.origin + eps.yxy,
                                           ray.direction)) -
                           distToScene(Ray(ray.origin - eps.yxy,
                                           ray.direction)),
                           
                           distToScene(Ray(ray.origin + eps.yyx,
                                           ray.direction)) -
                           distToScene(Ray(ray.origin - eps.yyx,
                                           ray.direction)));
    return normalize(normal);
}

/// Calculates `ambient occlusion` using `cone tracing` concept
float ambientOcclusion(float3 pos, float3 normal) {
    /// Both `cone radius` and `distance from the surface`
    float eps = .01;
    
    pos += normal * eps * 2.;
    float occlusion = 0.;
    
    for (float i = 1.; i < 10.; i++) {
        /// Get scene distance
        float dist = distToScene(Ray(pos, float3(0)));
        
        /// Double the radius, so we know how much of the cone is occlude
        float coneWidth = 2. * eps;
        
        /// Eliminate negative values for the light
        float occlusionAmount = max(coneWidth - dist, 0.);
        
        /// Get the amount (ratio) of occlusion scaled by the cone width
        float occlusionFactor = occlusionAmount / coneWidth;
        
        /// Set lower impact for more distant occluders (using iteration counter)
        occlusionFactor *= 1. - (i / 10.);
        
        /// Preserve the highest occlusion value so far
        occlusion = max(occlusion, occlusionFactor);
        
        /// Double the `eps` value
        eps *= 2.;
        
        /// Move along the normal by that distance
        pos += normal * eps;
    }
    return max(0., 1. - occlusion);
}

/// Sets up the camera
/// `pos` = position; `target` = look-at-target; `fov` = field of view; `uv` and `x` = view coordinates
Camera setupCam(float3 pos, float3 target, float fov, float2 uv, int x) {
    uv *= fov;
    float3 cw = normalize(target - pos);
    float3 cp = float3(0., 1., 0.);
    float3 cu = normalize(cross(cw, cp));
    float3 cv = normalize(cross(cu, cw));
    Ray ray = Ray(pos, normalize(uv.x * cu + uv.y * cv + .5 * cw));
    Camera cam = Camera(pos, ray, fov / float(x));
    return cam;
}

// MARK: - Compute

kernel void compute(texture2d<float, access::write> output [[ texture(0) ]],
                    constant float &timer [[ buffer(1) ]],
                    constant float2 &touch [[ buffer(2) ]],
                    uint2 gid [[ thread_position_in_grid ]]) {
    int width = output.get_width();
    int height = output.get_height();
    
    float2 uv = float2(gid) / float2(width, height);

    /// Center the scene
    uv.x -= .5;
    uv.y -= .5;
    
    uv.y = -uv.y;
    
    /// iOS workaround for scaling
    if (width > height) {
        uv.x /= .5;
    } else {
        uv.y /= .5;
    }
    
    float3 camPos = float3(sin(timer) * 10., 3., cos(timer) * 10.);
    Camera cam = setupCam(camPos, float3(0), 1.5, uv, width);
    
    /// Scene
    float3 color = float3(1.);
    bool hit = false;
    for (int i = 0; i < 200; i++) {
        float dist = distToScene(cam.ray);
        /// We "hit" the object if distance to the scene is within `0.001`
        if (dist < .001) {
            hit = true;
            break;
        }
        cam.ray.origin += cam.ray.direction * dist;
    }
    
    /// If we did not "hit" the object, just color everything in grey
    if (!hit) {
        color = float3(.5);
    } else {
        float3 normal = getNormal(cam.ray);
        float occlusion = ambientOcclusion(cam.ray.origin, normal);
        
        color = color * occlusion;
    }
        
    output.write(float4(color, 1.), gid);
}
