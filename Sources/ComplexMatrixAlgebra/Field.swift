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
protocol FieldOperable:RingOperable where A: Field, B:FieldBasis {
    var fieldOp: FieldOperators<A,B> { get }
    init(fieldOp:FieldOperators<A,B>)
}
extension FieldOperable where A.O == Self {
    var f:A {
        return A(op: self)
    }
}
indirect enum FieldOperators<A:Field,B:FieldBasis>:FieldOperable, Equatable {
    var fieldOp: Self {
        return self
    }
    
    init(fieldOp: Self) {
        self = fieldOp
    }
    
    init(ringOp: RingO) {
        self = .Ring(ringOp)
    }
    
    var ringOp: RingO? {
        switch self {
        case let .Ring(r):
            return r
        default:
            return nil
        }
    }
    
    case Quotient(A, A)
    case Inverse(A)
    case Power(base:A, exponent:A)
    case Conjugate(A)
    case Ring(RingOperators<A,B>)
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
    static prefix func ~ (lhs: Self) -> Self {
        return Self(op: .init(fieldOp: .Inverse(lhs)))
        
    }
    static prefix func * (lhs: Self) -> Self { return Self(op: .init(fieldOp: .Conjugate(lhs))) }

    static func / (lhs: Self, rhs: Self) -> Self { return .init(op: .init(fieldOp: .Quotient(lhs, rhs))) }
    static func ^ (lhs: Self, rhs: Self) -> Self { return .init(op: .init(fieldOp: .Power(base: lhs, exponent: rhs))) }
    func evalField() -> Self {
        switch op.fieldOp {
        case let .Ring(.Mul(x, y)):
            return operateFieldMul(x.eval(), y.eval())
        
        case let .Quotient(l, r):
            return (l * ~r).eval()
        
        case let .Inverse(x):
            let x = x.eval()
            switch x.op.fieldOp {
            case let .Ring(.Number(number)):
                return (~number).asNumber(Self.self)
            case let .Quotient(numer, denom):
                return Self(op: .init(fieldOp: .Quotient(denom, numer))).eval()
            case let .Inverse(x):
                return x.eval()
            default: break
            }
            return Self(op: .init(fieldOp: .Inverse(x)))
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
            switch exponent.op.fieldOp {
            case let .Ring(ring):
                switch ring {
                case let .Number(numExp):
                    switch base.op.ringOp {
                    case let .Number(numBase):
                        if let evaled = numBase^numExp {
                            return evaled.asNumber(Self.self)
                        }
                    default: break
                    }
                default: break
                }
            default: break
            }
            return Self(op: .init(fieldOp: .Power(base: base, exponent: exponent)))
        case let .Conjugate(xx):
            let x = xx.eval()
            switch x.op.ringOp {
            case let .Number(n):
                return (*n).asNumber(Self.self)
            default:
                return Self(op: .init(fieldOp: .Conjugate(x)))
            }
        default:
            break
        }
        return evalRing()
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
