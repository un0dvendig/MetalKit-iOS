//
//  Particle.swift
//  Particles Part 2
//
//  Created by Eugene Ilyin on 18.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import simd

struct Particle {
    
    // MARK: - Properties
    
    var initialMatrix = matrix_identity_float4x4
    var matrix = matrix_identity_float4x4
    var color = SIMD4<Float>()
    
}
