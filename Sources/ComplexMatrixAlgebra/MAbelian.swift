//
//  File.swift
//
//
//  Created by Ingun Jon on 2020/05/20.
//

import Foundation
public protocol MAbelianBasis:MMonoidBasis {
    static prefix func ~ (l:Self) throws ->Self
}

public indirect enum MAbelianOperator<A:MAbelian>:Operator {
    case Monoid(A.MMonO)
    case Quotient(A,A)
    case Inverse(A)
    
    public func eval() throws -> A {
        switch self {
        case let .Monoid(mon):
            if case let .Mul(_b) = mon {
                let l = try _b.l.eval()
                let r = try _b.r.eval()
                
                if case let .Inverse(l) = l.mabelianOp {
                    if l == r {
                        return .Id
                    }
                }
                if case let .Inverse(r) = r.mabelianOp {
                    if l == r {
                        return .Id
                    }
                }
                
                if case let .Mul(lm) = l.mmonoidOp {
                    if (true) {//(x*y)*r = (x*r)*y
                        let alter = (lm.x * r)
                        let aeval = try alter.eval()
                        if alter != aeval {
                            return try (aeval * lm.y).eval()
                        }
                    }
                }
                if case let .Mul(rm) = r.mmonoidOp {
                    if (true) {//l(xy) = x(ly)
                        let alter = (l * rm.y)
                        let aeval = try alter.eval()
                        if alter != aeval {
                            return try (rm.x * aeval).eval()
                        }
                    }
                }
            }
            return try mon.eval()
        case let .Quotient(l, r):
            return try (l * ~r).eval()
        case let .Inverse(x):
            let x = try x.eval()
            switch x.element {
            case let .Basis(x): return try .init(element: .Basis(~x))
            default: break
            }
            switch x.mmonoidOp {
            case let .Mul(bin): return try ((~bin.l) * (~bin.r)).eval()
            default: break
            }
            switch x.mabelianOp {
            case let .Inverse(x):
                return try x.eval()
            case let .Quotient(l, r):
                return try (r / l).eval()
            default: break
            }
        default: break
        }
        return .init(mabelianOp: self)
    }
}
public protocol MAbelian:MMonoid where B:MAbelianBasis, MUL:CommutativeMultiplication {
    typealias MAbelianO = MAbelianOperator<Self>
    init(mabelianOp:MAbelianO)
    var mabelianOp: MAbelianO? {get}
}
extension MAbelian {
    public static func / (lhs: Self, rhs: Self) -> Self {
        return .init(mabelianOp: .Quotient(lhs, rhs))
    }
    public static prefix func ~ (l:Self)-> Self {
        return .init(mabelianOp: .Inverse(l))
    }
    var mmonoidOp: MMonO? {
        switch mabelianOp {
        case let .Monoid(m): return m
        default: return nil
        }
    }
    init(mmonoidOp: MMonO) {
        self.init(mabelianOp: .Monoid(mmonoidOp))
    }
}
func flatMAbelianMul<A:MAbelian>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Mul(bin) = x.mmonoidOp {
            return [bin.l,bin.r]
        } else {
            return []
        }
    }
}
