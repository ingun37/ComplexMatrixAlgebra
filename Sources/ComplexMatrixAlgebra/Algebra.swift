//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit
indirect enum Element<B:Basis>:Equatable {
    case Basis(B)
    case Var(String)
}
protocol Operator:Equatable {
    associatedtype A:Algebra
    func eval() -> A
}
//TODO: Change once accepted: https://forums.swift.org/t/accepted-se-0280-enum-cases-as-protocol-witnesses/34850
protocol Algebra: Equatable {
    associatedtype B:Basis
    associatedtype O:Operator where O.A == Self
    var o: O? {
        get
    }
    func same(_ to:Self)-> Bool
    
    init(element:Element<B>)
    var element: Element<B>? {get}
}
extension Algebra {
    func same(algebra:Self)-> Bool {
        switch (element, algebra.element) {
        case let (.Basis(x), .Basis(y)):
            return x == y
        case let (.Var(x),.Var(y)):
            return x == y
        default: return self == algebra
        }
    }
    func eval() -> Self {
        return o?.eval() ?? self
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
