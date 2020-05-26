//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/16.
//

import Foundation

protocol FieldBasis: RingBasis {
    static func / (lhs: Self, rhs: Self) -> Self
    static prefix func ~ (lhs: Self) -> Self
    static prefix func * (lhs: Self) -> Self
    static func whole(n:Int)->Self
}


protocol FieldMulitplication:CommutativeBinary where A:Field {}
protocol Field:Ring where B:FieldBasis, MUL: FieldMulitplication {
    var fieldOp: FieldOperators<Self>? { get }
    init(fieldOp:FieldOperators<Self>)
}

indirect enum FieldOperators<A:Field>: Operator {
    func eval() -> A {
        
        switch self {
        case let .Ring(ring):
            if case let .MMonoid(.Mul(b)) = ring {
                let l = b.l.eval()
                let r = b.r.eval()
                if case let .Mul(lm) = l.mmonoidOp {
//                    if (true) {//(x*y)*r = (r*y)*x
//                        let alter = (r * lm.y)
//                        let aeval = alter.eval()
//                        if alter != aeval {
//                            return (aeval * lm.x).eval()
//                        }
//                    }
                    if (true) {//(x*y)*r = (x*r)*y
                        let alter = (lm.x * r)
                        let aeval = alter.eval()
                        if alter != aeval {
                            return (aeval * lm.y).eval()
                        }
                    }
                }
                if case let .Mul(rm) = r.mmonoidOp {
                    if (true) {//l(xy) = x(ly)
                        let alter = (l * rm.y)
                        let aeval = alter.eval()
                        if alter != aeval {
                            return (rm.x * aeval).eval()
                        }
                    }
//                    if (true) {//l(xy) = y(xl)
//                        let alter = (rm.x * l)
//                        let aeval = alter.eval()
//                        if alter != aeval {
//                            return (rm.y * aeval).eval()
//                        }
//                    }
                }
            }
            return ring.eval()
        case let .Quotient(l, r): return (l * ~r).eval()
        
        case let .Inverse(x):
            let x = x.eval()
            switch x.element {
            case let .Basis(number):
                return .init(element: .Basis(~number))
            default: break
            }
            
            switch x.fieldOp {
            case let .Quotient(numer, denom):
                return A(fieldOp: .Quotient(denom, numer)).eval()
            case let .Inverse(x):
                return x.eval()
            default: break
            }
            return .init(fieldOp: .Inverse(x))
        case .Power(base: let _base, exponent: let _exponent):
            let base = _base.eval()
            let exponent = _exponent.eval()
            if exponent == .Zero {
                return .Id
            } else if exponent == .Id {
                return base
            } else if exponent == ._Id {
                return ~base
            }
            return .init(fieldOp: .Power(base: base, exponent: exponent))
        case let .Conjugate(xx):
            let x = xx.eval()
            switch x.element {
            case let .Basis(n):
                return .init(element: .Basis(*n))
            default: break
            }
            return .init(fieldOp: .Conjugate(x))
        case let .Determinant(m):
            let m = m.eval()
            if case let .e(.Basis(m)) = m.c {
                if let d = m.determinant {
                    return d
                }
            }
            return .init(fieldOp: .Determinant(m))
        }
    }
    
    case Quotient(A, A)
    case Inverse(A)
    case Power(base:A, exponent:A)
    case Conjugate(A)
    case Ring(A.RingOp)
    case Determinant(Matrix<A>)
}

/** conjugate prefix */
prefix operator *

extension Field {
    static prefix func ~ (lhs: Self) -> Self {
        return .init(fieldOp: .Inverse(lhs))
    }
    static prefix func * (lhs: Self) -> Self { return .init(fieldOp: .Conjugate(lhs)) }
    static func / (lhs: Self, rhs: Self) -> Self { return .init(fieldOp: .Quotient(lhs, rhs)) }
    static func ^ (lhs: Self, rhs: Self) -> Self { return .init(fieldOp: .Power(base: lhs, exponent: rhs)) }

    init(ringOp: RingOp) {
        self.init(fieldOp: .Ring(ringOp))
    }
    var ringOp: RingOp? {
        switch fieldOp {
        case let .Ring(r):
            return r
        default:
            return nil
        }
    }
}


func operateFieldMul<A:Field>(_ x:A, _ y:A)-> A {
    return operateCommutativeBinary({ (_ l: A, _ r: A) -> A? in
        if case let .Add(b) = l.abelianOp {
            let xr = b.l * r
            let yr = b.r * r
            return (xr + yr).eval()
        } else if l == A.Id {
            return r
        } else if l == A.Zero {
            return A.Zero
        } else if case let (.Basis(ln), .Basis(rn)) = (l.element,r.element) {
            return (ln * rn).asNumber(A.self)
        }
        switch (l.fieldOp,r.fieldOp) {
        case (.Power(base: let lbase, exponent: let lexp), .Power(base: let rbase, exponent: let rexp)):
            if lbase == (rbase) {
                return A(fieldOp: .Power(base: lbase, exponent: lexp + rexp)).eval()
            }
        default:
            return nil
        }
        return nil
    }, flatRingMul(x) + flatRingMul(y)).reduce(*)
}


