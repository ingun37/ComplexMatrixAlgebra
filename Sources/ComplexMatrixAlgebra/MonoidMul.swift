//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/24.
//

import Foundation
indirect enum MonoidMulOperators<A:MonoidMul>:Operator {
    case Mul(A.MUL)
    func eval() -> A {
        switch self {
        case let .Mul(b):
            return associativeMerge(_objs: b.flat()) { (l, r) -> A? in
                if l == .Id {
                    return r
                }
                if case let (.Basis(ln), .Basis(rn)) = (l.element,r.element) {
                    return A(element: .Basis(ln * rn))
                }
                return nil
            }.reduce(*)
        }
    }
}

protocol MonoidMulBasis:Basis {
    static func * (l:Self, r:Self)->Self
    static var Id:Self {get}
}
protocol MonoidMul:Algebra where B:MonoidMulBasis {
    associatedtype MUL:AssociativeBinary where MUL.A == Self
    typealias MonMulOp = MonoidMulOperators<Self>
    init(monoidMulOp:MonMulOp)
    var monoidMulOp: MonMulOp? { get }
}
extension MonoidMul {
    static var Id:Self {
        return .init(element: .Basis(.Id))
    }
    static func * (l:Self, r:Self)->Self {
        return .init(monoidMulOp: .Mul(.init(l: l, r: r)))
    }
}
