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
            fatalError()
        }
    }
    
    
    
}
protocol MonoidMulBasis:Basis {
    static func * (l:Self, r:Self)->Self
    static var Id:Self {get}
}
protocol MonoidMul:Algebra {
    associatedtype MUL:AssociativeBinary where MUL.A == Self
}

//func multiplyMonoid<A:MonoidMul>(_ x:A, _ y:A)-> A {
//    return associativeMerge(_objs: flatRingMul(x) + flatRingMul(y)) { (l, r) -> A? in
//        if case let (.Basis(ln), .Basis(rn)) = (l.element,r.element) {
//            return (ln * rn).asNumber(A.self)
//        }
//        return nil
//    }.reduce(*)
//}
