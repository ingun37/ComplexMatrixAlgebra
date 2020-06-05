//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/24.
//

import Foundation
public indirect enum MMonoidOperators<A:MMonoid>:Operator {
    case Mul(A.MUL)
    public func eval() -> A {
        switch self {
        case let .Mul(_b):
            let l = _b.l.eval()
            let r = _b.r.eval()
            
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
}

public protocol MMonoidBasis:Basis {
    static func * (l:Self, r:Self)->Self
    static var Id:Self {get}
}
public protocol MMonoid:Algebra where B:MMonoidBasis {
    associatedtype MUL:AssociativeMultiplication where MUL.A == Self
    typealias MMonO = MMonoidOperators<Self>
    init(mmonoidOp:MMonO)
    var mmonoidOp: MMonO? { get }
}
extension MMonoid {
    public static var Id:Self {
        return .init(element: .Basis(.Id))
    }
    public static func * (l:Self, r:Self)->Self {
        return .init(mmonoidOp: .Mul(.init(l: l, r: r)))
    }
}
