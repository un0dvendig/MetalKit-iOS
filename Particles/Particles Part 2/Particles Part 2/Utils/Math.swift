//
//  Math.swift
//  Particles Part 2
//
//  Created by Eugene Ilyin on 18.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import simd

func translate(by: SIMD3<Float>) -> float4x4 {
    return float4x4([
        SIMD4<Float>( 1,  0,  0,  0),
        SIMD4<Float>( 0,  1,  0,  0),
        SIMD4<Float>( 0,  0,  1,  0),
        SIMD4<Float>( by.x,  by.y,  by.z,  1)
    ])
}
