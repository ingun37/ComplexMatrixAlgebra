//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit
indirect enum BasisNullary<B:Basis>:Equatable {
    case Number(B)
    case Var(String)
}

//TODO: Change once accepted: https://forums.swift.org/t/accepted-se-0280-enum-cases-as-protocol-witnesses/34850
protocol Algebra: Equatable {
    associatedtype B:Basis
    
    func eval() -> Self
    func same(_ to:Self)-> Bool
    
    init(basis:BasisNullary<B>)
    var basis: BasisNullary<B>? {get}
}
extension Algebra {
    func same(algebra:Self)-> Bool {
        switch (basis, algebra.basis) {
        case let (.Number(x), .Number(y)):
            return x == y
        case let (.Var(x),.Var(y)):
            return x == y
        default: return self == algebra
        }
    }
    func evalAlgebra() -> Self {
        return self
    }
}
protocol Basis:Equatable {}

func commuteSame<C:Collection, T:Algebra>(_ xs:C, _ ys:C) -> Bool where C.Element == T, C.Index == Int{
    guard xs.count == ys.count else { return false }
    let len = xs.count
    if len == 0 { return true }
    let aa = (0..<len).flatMap({i in (0..<len).map({(i,$0)})})
    if let match = aa.first(where: { xs[$0].same(ys[$1]) }) {
        return commuteSame(xs.without(at:match.0), ys.without(at: match.1))
    } else {
        return false
    }
    
}
