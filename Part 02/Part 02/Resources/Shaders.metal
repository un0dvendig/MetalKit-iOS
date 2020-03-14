//
//  Shaders.metal
//  Part 02
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex {
    float4 position [[ position ]];
};

vertex Vertex vertex_func(const device Vertex* vertices [[ buffer(0) ]],
                          uint vid [[ vertex_id ]]) {
    return vertices[vid];
}

fragment float4 fragment_func(Vertex vert [[ stage_in ]]) {
    return float4(0.7, 1, 1, 1);
}
