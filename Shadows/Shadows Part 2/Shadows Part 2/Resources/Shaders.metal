//
//  Shaders.metal
//  Shadows Part 2
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

struct Plane {
    float yCoord;
    
    Plane(float y) {
        yCoord = y;
    }
};

struct Light {
    float3 position;
    
    Light(float3 pos) {
        position = pos;
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

float distToPlane(Ray ray, Plane plane) {
    return ray.origin.y - plane.yCoord;
}

/// Gives the closest distance to any object in the scene
float distToScene(Ray ray) {
    Plane plane = Plane(0.);
    float distanceToPlane = distToPlane(ray, plane);
    Sphere sphere0 = Sphere(float3(2.), 1.9);
    Sphere sphere1 = Sphere(float3(0., 4., 0.), 4.);
    Sphere sphere2 = Sphere(float3(0., 4., 0.), 3.9);
    Ray repeatRay = ray;
    repeatRay.origin = fract(ray.origin / 4.) * 4.;
    float distToSphere0 = distToSphere(repeatRay, sphere0);
    float distToSphere1 = distToSphere(ray, sphere1);
    float distToSphere2 = distToSphere(ray, sphere2);
    float dist = differenceOp(distToSphere1, distToSphere2);
    dist = differenceOp(dist, distToSphere0);
    dist = unionOp(distanceToPlane, dist);
    return dist;
}

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

/// Calculates lighting
float lighting(Ray ray, float3 normal, Light light) {
    float3 lightRay = normalize(light.position - ray.origin);
    
    /// For diffuse lighting we need angle between the `normal` the the `lightray`,
    /// that is, the dot product of the two
    float diffuse = max(0., dot(normal, lightRay));
    
    float3 reflectedray = reflect(ray.direction, normal);
    /// For specular lighting we need reflections on surfaces
    float specular = max(0., dot(reflectedray, lightRay));
    specular = pow(specular, 200.);
    return diffuse + specular;
}

/// Calculates `soft shadows`
/// Uses `attenuator` to get various (intermediate) values of light
float shadow(Ray ray, float attenuator, Light light) {
    float3 lightDir = light.position - ray.origin;
    float lightDist = length(lightDir);
    lightDir = normalize(lightDir);
    
    /// The `eps` variable tells how much wider the beam is as we go out into the scene
    float eps = .1;
    
    /// Starting with a small `distAlongRay` because otherwise the surface at this point would shadow itself
    float distAlongRay = eps * 2.;
    
    /// Starting with a white `(1.0)` light
    float l = 1.;
    
    /// Travel along the ray
    for (int i = 0; i < 100; i++) {
        Ray lightRay = Ray(ray.origin + lightDir * distAlongRay,
                           lightDir);
        float dist = distToScene(lightRay);
        
        /// Substruct `dist` from `eps` (the beam width) and divide it by `eps` to get the percentage of
        /// beam covered. If we invert it `(1 - beam width)` we get the percentage of beam that is in the light.
        /// We take `min` of this new value and `light` to preserve the darkest shadow as we march
        l = min(l, 1. - (eps - dist) / eps);
        
        /// Move aling the ray and increase the beam width in proportion to the distance traveled
        /// scaled by `attenuator`
        distAlongRay += dist * .5;
        eps += dist * attenuator;
        
        /// If we're past the light, break ou of the loop
        if (distAlongRay > lightDist) {
            break;
        }
    }
    /// To avoid negative values for the light, return `maximum` between `0.0` and value of `l` [light]
    return max(l, 0.);
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
    /// Center the drawing
    uv.x -= .5;
    uv.y -= .5;
    
    uv.y = -uv.y;
    
    /// iOS workaround for scaling
    if (width > height) {
        uv.x /= .5;
    } else {
        uv.y /= .5;
    }

    /// Scene
    Ray ray = Ray(float3(0., 4., -12.),
                  normalize(float3(uv, 1.0)));
    float3 color = float3(1.);
    bool hit = false;
    for (int i = 0; i < 200; i++) {
        float dist = distToScene(ray);
        /// We "hit" the object if distance to the scene is within `0.001`
        if (dist < .001) {
            hit = true;
            break;
        }
        ray.origin += ray.direction * dist;
    }
    
    /// Lighting + Shadows
    /// If we did not "hit" the object, just color everything in grey
    if (!hit) {
        color = float3(.5);
    } else {
        float3 normal = getNormal(ray);
        Light light = Light(float3(sin(timer) * 10.,
                                   5.,
                                   cos(timer) * 10.));
        float l = lighting(ray, normal, light);
        
        /// Shadows
        float s = shadow(ray, .3, light);
        
        color = color * l * s;
    }
    
    /// Another (fixed) light source in the front of the scene
    Light light2 = Light(float3(0., 5., -15.));
    float3 lightRay = normalize(light2.position - ray.origin);
    float fl = max(0., dot(getNormal(ray), lightRay) / 2.);
    color += fl;
    
    output.write(float4(color, 1.), gid);
}
