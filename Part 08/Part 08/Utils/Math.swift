//
//  Math.swift
//  Part 08
//
//  Created by Eugene Ilyin on 13.03.2020.
//  Copyright © 2020 Eugene Ilyin. All rights reserved.
//

import simd

// MARK: - Methods

func translationMatrix(position: simd_float3) -> matrix_float4x4 {
    let X = simd_float4(1, 0, 0, 0)
    let Y = simd_float4(0, 1, 0, 0)
    let Z = simd_float4(0, 0, 1, 0)
    let W = simd_float4(position.x, position.y, position.z, 1)
    return matrix_float4x4(columns:(X, Y, Z, W))
}

func scalingMatrix(scale: Float) -> matrix_float4x4 {
    let X = simd_float4(scale, 0, 0, 0)
    let Y = simd_float4(0, scale, 0, 0)
    let Z = simd_float4(0, 0, scale, 0)
    let W = simd_float4(0, 0, 0, 1)
    return matrix_float4x4(columns:(X, Y, Z, W))
}

func rotationMatrix(angle: Float, axis: simd_float3) -> matrix_float4x4 {
    var X = simd_float4(0, 0, 0, 0)
    X.x = axis.x * axis.x + (1 - axis.x * axis.x) * cos(angle)
    X.y = axis.x * axis.y * (1 - cos(angle)) - axis.z * sin(angle)
    X.z = axis.x * axis.z * (1 - cos(angle)) + axis.y * sin(angle)
    X.w = 0.0
    var Y = simd_float4(0, 0, 0, 0)
    Y.x = axis.x * axis.y * (1 - cos(angle)) + axis.z * sin(angle)
    Y.y = axis.y * axis.y + (1 - axis.y * axis.y) * cos(angle)
    Y.z = axis.y * axis.z * (1 - cos(angle)) - axis.x * sin(angle)
    Y.w = 0.0
    var Z = simd_float4(0, 0, 0, 0)
    Z.x = axis.x * axis.z * (1 - cos(angle)) - axis.y * sin(angle)
    Z.y = axis.y * axis.z * (1 - cos(angle)) + axis.x * sin(angle)
    Z.z = axis.z * axis.z + (1 - axis.z * axis.z) * cos(angle)
    Z.w = 0.0
    let W = simd_float4(0, 0, 0, 1)
    return matrix_float4x4(columns:(X, Y, Z, W))
}

func projectionMatrix(near: Float, far: Float, aspect: Float, fovy: Float) -> matrix_float4x4 {
    let scaleY = 1 / tan(fovy * 0.5)
    let scaleX = scaleY / aspect
    let scaleZ = -(far + near) / (far - near)
    let scaleW = -2 * far * near / (far - near)
    let X = simd_float4(scaleX, 0, 0, 0)
    let Y = simd_float4(0, scaleY, 0, 0)
    let Z = simd_float4(0, 0, scaleZ, -1)
    let W = simd_float4(0, 0, scaleW, 0)
    return matrix_float4x4(columns:(X, Y, Z, W))
}

