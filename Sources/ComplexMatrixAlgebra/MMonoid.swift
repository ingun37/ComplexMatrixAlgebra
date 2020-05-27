//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/24.
//

import Foundation
indirect enum MMonoidOperators<A:MMonoid>:Operator {
    case Mul(A.MUL)
    func eval() -> A {
        switch self {
        case let .Mul(b):
            let l = b.l.eval()
            let r = b.r.eval()
            
            return Self.evalMul(evaledL: l, evaledR: r)
        }
    }
    static func evalMul(evaledL:A, evaledR:A) -> A {//seperated it for optimizating purpose
        let l = evaledL
        let r = evaledR
        if l == .Id { return r }
        if r == .Id { return l }
        
        if case let .Basis(lb) = l.element {
            if case let .Basis(rb) = r.element {
                return A(element: .Basis(lb * rb))
            }
        }
        
        if case let .Mul(lm) = l.mmonoidOp {
            //(xy)r = x(yr)
            let alter = (lm.r * r)
            let aeval = alter.eval()
            if alter != aeval {
                return (lm.l * aeval).eval()
            }
        }
        
        if case let .Mul(rm) = r.mmonoidOp {
            //l(xy) = (lx)y
            let alter = (l * rm.l)
            let aeval = alter.eval()
            if alter != aeval {
                return (aeval * rm.r).eval()
            }
        }
        
        return l * r
    }
}

protocol MMonoidBasis:Basis {
    static func * (l:Self, r:Self)->Self
    static var Id:Self {get}
}
protocol MMonoid:Algebra where B:MMonoidBasis {
    associatedtype MUL:AssociativeBinary where MUL.A == Self
    typealias MMonO = MMonoidOperators<Self>
    init(mmonoidOp:MMonO)
    var mmonoidOp: MMonO? { get }
}
extension MMonoid {
    static var Id:Self {
        return .init(element: .Basis(.Id))
    }
    static func * (l:Self, r:Self)->Self {
        return .init(mmonoidOp: .Mul(.init(l: l, r: r)))
    }
}
