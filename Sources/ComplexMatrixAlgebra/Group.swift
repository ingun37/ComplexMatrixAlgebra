//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/18.
//

import Foundation


protocol AbelianAddGroupSet:Underlying {
    static var zero: Self {get}
    static func + (lhs: Self, rhs: Self) -> Self
    /**
     abelian group add inverse
     */
    static func - (lhs: Self, rhs: Self) -> Self
}
