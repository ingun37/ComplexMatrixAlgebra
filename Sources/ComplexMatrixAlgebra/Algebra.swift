//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation

protocol Algebra: Equatable {
    func eval() -> Self
    func iso(_ to:Self) -> Bool
}

/**
 
 */
protocol AlgebraBinaryOperator {
    associatedtype Alg where Alg:Algebra
    var l: Alg { get }
    var r: Alg { get }
}
extension AlgebraBinaryOperator {//associativity flat
    static func associativeFlat(m:Alg) -> [Alg] {
        if let m = m as? Self {
            return associativeFlat(m: m.l) + associativeFlat(m: m.r)
        } else {
            return [m]
        }
    }
    
    func associativeFlat() -> [Alg] {
        return Self.associativeFlat(m: l) + Self.associativeFlat(m: r)
    }
    
    func commutativeIso(_ to: Self) -> Bool {
        let xs = associativeFlat()
        let ys = to.associativeFlat()
        guard xs.count == ys.count else { return false }
        let match = xs.permutations().first { (xs_) -> Bool in
            zip(xs_, ys).allSatisfy { (x,y) -> Bool in
                x.iso(y)
            }
        }
        return match != nil
    }
    
    func eq(_ to: Self) -> Bool {
        return l == to.l && r == to.r
    }
}

protocol AlgebraUnaryOperator {//Negate and such
    associatedtype Alg where Alg:Algebra

}
