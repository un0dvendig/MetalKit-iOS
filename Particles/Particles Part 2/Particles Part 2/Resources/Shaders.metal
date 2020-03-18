//
//  Shaders.metal
//  Particles Part 2
//
//  Created by Eugene Ilyin on 18.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Objects

struct VertexIn {
    float4 position [[ attribute(0) ]];
};

struct VertexOut {
    float4 position [[ position ]];
    float4 color;
};

struct Particle {
    float4x4 initial_matrix;
    float4x4 matrix;
    float4 color;
};

// MARK: - Compute

vertex VertexOut vertex_main(const VertexIn vertex_in [[ stage_in ]],
                             constant Particle *particles [[ buffer(1) ]],
                             uint instanceid [[ instance_id ]]) {
    VertexOut vertex_out;
    Particle particle = particles[instanceid];
    vertex_out.position = particle.matrix * vertex_in.position;
    vertex_out.color = particle.color;
    return vertex_out;
}

fragment float4 fragment_main(VertexOut vertex_in [[ stage_in ]]) {
    return vertex_in.color;
}
