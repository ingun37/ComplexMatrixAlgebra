//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/16.
//

import Foundation

protocol FieldSet: AbelianAddGroupSet {
    static var id: Self {get}
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
    static prefix func - (lhs: Self) -> Self
    static prefix func ~ (lhs: Self) -> Self
    static prefix func * (lhs: Self) -> Self
    static func ^ (lhs: Self, rhs: Self) -> Self?
}
extension FieldSet {
    static func ^ (lhs: Self, rhs: Int) -> Self {
        if rhs == 0 {
            return id
        } else if rhs < 0 {
            let inv = ~lhs
            return (rhs+1..<0).map({_ in inv}).reduce(inv, *).eval()
        } else {
            return (1..<rhs).map({_ in lhs}).reduce(lhs, *).eval()
        }
    }
}


/**
 conjugation prefix
 */
