//
//  Matrix.swift
//  Part 7
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
}
