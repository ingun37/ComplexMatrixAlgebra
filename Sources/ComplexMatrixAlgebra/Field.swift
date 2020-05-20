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
    static func ^ (lhs: Self, rhs: Self) -> Self?
}
extension FieldBasis {
    static func ^ (lhs: Self, rhs: Int) -> Self {
        if rhs == 0 {
            return Id
        } else if rhs < 0 {
            let inv = ~lhs
            return (rhs+1..<0).map({_ in inv}).reduce(inv, *)
        } else {
            return (1..<rhs).map({_ in lhs}).reduce(lhs, *)
        }
    }
}

protocol Field:Ring where O:FieldOperable {
}
protocol FieldOperable:RingOperable where A: Field, U:FieldBasis {
    typealias O = FieldOperators<A,U>
    var fieldOp: O { get }
    init(fieldOp:O)
}
extension FieldOperable where A.O == Self {
    var asField:A {
        return A(op: self)
    }
}
indirect enum FieldOperators<F:Equatable,Num:Equatable>:Equatable {
    case Quotient(F, F)
    case Subtract(F, F)
    case Var(String)
    case Inverse(F)
    case Power(base:F, exponent:F)
    case Conjugate(F)
    case Ring(RingOperators<F,Num>)
}

extension FieldOperators where F:Field, Num == F.O.U {
    var asSum: F.O { return F.O(fieldOp: self)}
    var f: F {
        return asSum.asField
    }
}

/** conjugate prefix */
prefix operator *

extension Field {
    func sameField(_ to: Self) -> Bool {
        switch (op.fieldOp, to.op.fieldOp) {
        case let (.Ring(ringL), .Ring(ringR)):
            switch (ringL,ringR) {
            case let (.Add(_,_), .Add(_,_)):
                return commuteSame(flatAdd(self).all, flatAdd(to).all)
            case let (.Mul(xl,xr), .Mul(yl,yr)):
                return commuteSame(flatMul(self).all, flatMul(to).all)
            default: break
            }
        default: break
        }
        return self == to

    }
    static prefix func ~ (lhs: Self) -> Self { return O.O.Inverse(lhs).f }
    static prefix func * (lhs: Self) -> Self { return O.O.Conjugate(lhs).f }

    static func - (lhs: Self, rhs: Self) -> Self { return O.O.Subtract(lhs, rhs).f }
    static func / (lhs: Self, rhs: Self) -> Self { return O.O.Quotient(lhs, rhs).f }
    static func ^ (lhs: Self, rhs: Self) -> Self { return O.O.Power(base: lhs, exponent: rhs).f }
    
    func evalField() -> Self {
        switch op.fieldOp {
        case let .Ring(ringOp):
            switch ringOp {
            case let .Mul(x,y):
                return operateFieldMul(x.eval(), y.eval())
            default:
                return evalRing()
            }
        
        case let .Quotient(l, r):
            return (l * ~r).eval()
        case let .Subtract(l, r):
            return (l + -r).eval()
        
        case .Var(_):
            return self
        case let .Inverse(x):
            let x = x.eval()
            switch x.op.fieldOp {
            case let .Ring(ring):
                switch ring {
                case let .Number(number):
                    return O.RingO.Number(~number).sum.asField
                default: break
                }
            
            case let .Quotient(numer, denom):
                return O.O.Quotient(denom, numer).f.eval()
            case let .Inverse(x):
                return x.eval()
            default: break
            }
            return O.O.Inverse(x).f
        case .Power(base: let _base, exponent: let _exponent):
            let base = _base.eval()
            let exponent = _exponent.eval()
            switch exponent.op.fieldOp {
            case let .Ring(ring):
                switch ring {
                case let .Number(numExp):
                    if numExp == .Zero {
                        return O.RingO.Number(.Id).sum.asField
                    } else if numExp == .Id {
                        return base
                    } else if numExp == -.Id {
                        return ~base
                    }
                    switch base.op.ringOp {
                    case let .Number(numBase):
                        if let evaled = numBase^numExp {
                            return O.RingO.Number(evaled).sum.asField
                        }
                    default: break
                    }
                default: break
                }
            default: break
            }
            return O.O.Power(base: base, exponent: exponent).f
        case let .Conjugate(xx):
            let x = xx.eval()
            switch x.op.ringOp {
            case let .Number(n):
                return O.RingO.Number(*n).sum.asField
            default:
                return O.O.Conjugate(x).f
            }
        }
    }
}


protocol ACBinary:Equatable {
    associatedtype A:Field
    var l: A {get}
    var r: A {get}
    static func match(_ a:A)->Self?
    static func tryCollapse(_ l:A, _ r:A)-> A?
    static func operation(lhs:A, rhs:A)-> A
    init(_ l:A, _ r:A)
}
