//
//  Matrix.swift
//  Part 08
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import simd

struct Matrix {
    
    // MARK: - Properties
    
    var m: [Float]
    
    // MARK: - Initialization
    
    init() {
        m = [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        ]
    }
    
    // MARK: - Methods
    
    func translationMatrix(_ matrix: Matrix, position: simd_float3) -> Matrix {
        var matrix = matrix
        matrix.m[12] = position.x
        matrix.m[13] = position.y
        matrix.m[14] = position.z
        return matrix
    }
    
    func scalingMatrix(_ matrix: Matrix, scale: Float) -> Matrix {
        var matrix = matrix
        matrix.m[0] = scale
        matrix.m[5] = scale
        matrix.m[10] = scale
        matrix.m[15] = 1.0
        return matrix
    }
    
    func rotationMatrix(_ matrix: Matrix, rotation: simd_float3) -> Matrix {
        var matrix = matrix
        matrix.m[0] = cos(rotation.y) * cos(rotation.z)
        matrix.m[4] = cos(rotation.z) * sin(rotation.x) * sin(rotation.y) - cos(rotation.x) * sin(rotation.z)
        matrix.m[8] = cos(rotation.x) * cos(rotation.z) * sin(rotation.y) + sin(rotation.x) * sin(rotation.z)
        matrix.m[1] = cos(rotation.y) * sin(rotation.z)
        matrix.m[5] = cos(rotation.x) * cos(rotation.z) + sin(rotation.x) * sin(rotation.y) * sin(rotation.z)
        matrix.m[9] = -cos(rotation.z) * sin(rotation.x) + cos(rotation.y) * sin(rotation.y) * sin(rotation.z)
        matrix.m[2] = -sin(rotation.y)
        matrix.m[6] = cos(rotation.y) * sin(rotation.x)
        matrix.m[10] = cos(rotation.x) * cos(rotation.y)
        matrix.m[15] = 1.0
        return matrix
    }
    
    func modelMatrix(matrix: Matrix) -> Matrix {
        var matrix = matrix
        
        let rotation = simd_float3(0.0, 0.0, 0.1)
        matrix = rotationMatrix(matrix, rotation: rotation)

        matrix = scalingMatrix(matrix, scale: 0.25)

        let position = simd_float3(0.0, 0.5, 0.0)
        matrix = translationMatrix(matrix, position: position)
        
        return matrix
    }
    
}
