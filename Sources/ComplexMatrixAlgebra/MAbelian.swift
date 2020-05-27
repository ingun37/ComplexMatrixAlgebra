//
//  File.swift
//
//
//  Created by Ingun Jon on 2020/05/20.
//

import Foundation
protocol MAbelianBasis:MMonoidBasis {
    static prefix func ~ (l:Self)->Self
}

indirect enum MAbelianOperator<A:MAbelian>:Operator {
    case Monoid(A.MMonO)
    case Quotient(A,A)
    case Inverse(A)
    
    func eval() -> A {
        switch self {
        case let .Monoid(mon):
            if case let .Mul(bin) = mon {
                let l = bin.l.eval()
                let r = bin.r.eval()
                
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
                
                if case let .Mul(ladd) = l.mmonoidOp {
                    let (x,y) = (ladd.x, ladd.y)
                    
                    // commutativity (x*y)*r = (x*r)*y
                    let alter2 = x * r
                    let aeval2 = alter2.eval()
                    if alter2 != aeval2 {
                        return (aeval2 * y).eval()
                    }
                }
                if case let .Mul(radd) = r.mmonoidOp {
                    let (x,y) = (radd.x, radd.y)
                    // commutativity l*(x*y) = x*(l*y)
                    let alter1 = l*y
                    let aeval1 = alter1.eval()
                    if alter1 != aeval1 {
                        return (x*aeval1).eval()
                    }
                }
                return A.MMonO.evalMul(evaledL: l, evaledR: r)
            }
            return mon.eval()
        case let .Quotient(l, r):
            return (l * ~r).eval()
        case let .Inverse(x):
            let x = x.eval()
            switch x.element {
            case let .Basis(x): return .init(element: .Basis(~x))
            default: break
            }
            switch x.mmonoidOp {
            case let .Mul(bin): return ((~bin.l) * (~bin.r)).eval()
            default: break
            }
            switch x.mabelianOp {
            case let .Inverse(x):
                return x.eval()
            case let .Quotient(l, r):
                return (r / l).eval()
            default: break
            }
        default: break
        }
        return .init(mabelianOp: self)
    }
}
protocol MAbelian:MMonoid where B:MAbelianBasis, MUL:CommutativeBinary {
    typealias MAbelianO = MAbelianOperator<Self>
    init(mabelianOp:MAbelianO)
    var mabelianOp: MAbelianO? {get}
}
extension MAbelian {
    static func / (lhs: Self, rhs: Self) -> Self {
        return .init(mabelianOp: .Quotient(lhs, rhs))
    }
    static prefix func ~ (l:Self)-> Self {
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
