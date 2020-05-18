//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/16.
//

import Foundation

protocol FieldSet: AbelianAddGroupSet {
    static var id: Self {get}
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
    static prefix func - (lhs: Self) -> Self
    static prefix func ~ (lhs: Self) -> Self
    static prefix func * (lhs: Self) -> Self
    static func ^ (lhs: Self, rhs: Self) -> Self?
}
extension FieldSet {
    static func ^ (lhs: Self, rhs: Int) -> Self {
        if rhs == 0 {
            return id
        } else if rhs < 0 {
            let inv = ~lhs
            return (rhs+1..<0).map({_ in inv}).reduce(inv, *)
        } else {
            return (1..<rhs).map({_ in lhs}).reduce(lhs, *)
        }
    }
}

protocol Field:Algebra where OpSum:FieldOpSum {
}
protocol FieldOpSum:OperatorSum where A: Field, Num:FieldSet {
    typealias O = FieldOperators<A,Num>
    var op: O { get }
    init(op:O)
}
extension FieldOpSum where A.OpSum == Self {
    var asField:A {
        return A(op: self)
    }
}
indirect enum FieldOperators<F:Equatable,Num:Equatable>:Equatable {
    
    case Number(Num)
    case Add(F,F)
    case Mul(F,F)
    case Quotient(F, F)
    case Subtract(F, F)
    case Negate(F)
    case Var(String)
    case Inverse(F)
    case Power(base:F, exponent:F)
    case Conjugate(F)
}

extension FieldOperators where F:Field, Num == F.OpSum.Num {
    var asSum: F.OpSum { return F.OpSum(op: self)}
    var f: F {
        return asSum.asField
    }
}

/** conjugate prefix */
prefix operator *

extension Field {
    func sameField(_ to: Self) -> Bool {
        switch (op.op, to.op.op) {
        case let (.Add(_,_), .Add(_,_)):
            return commuteSame(flatAdd(self).all, flatAdd(to).all)
        case let (.Mul(xl,xr), .Mul(yl,yr)):
            return commuteSame(flatMul(self).all, flatMul(to).all)
        default:
            return self == to
        }
    }
    static prefix func ~ (lhs: Self) -> Self { return OpSum.O.Inverse(lhs).f }
    static prefix func - (lhs: Self) -> Self { return OpSum.O.Negate(lhs).f }
    static prefix func * (lhs: Self) -> Self { return OpSum.O.Conjugate(lhs).f }

    static func - (lhs: Self, rhs: Self) -> Self { return OpSum.O.Subtract(lhs, rhs).f }
    static func + (lhs: Self, rhs: Self) -> Self { return OpSum.O.Add(lhs, rhs).f }
    static var zero: Self { return OpSum.O.Number(OpSum.Num.zero).f}
    static var id: Self{ return OpSum.O.Number(OpSum.Num.id).f}
    static var _id: Self{ return OpSum.O.Number(-OpSum.Num.id).f}
    static func / (lhs: Self, rhs: Self) -> Self { return OpSum.O.Quotient(lhs, rhs).f }
    static func * (lhs: Self, rhs: Self) -> Self { return OpSum.O.Mul(lhs, rhs).f }
    static func ^ (lhs: Self, rhs: Self) -> Self { return OpSum.O.Power(base: lhs, exponent: rhs).f }
    
    func evalField() -> Self {
        switch op.op {
        case let .Number(number): return OpSum.O.Number(number).f
        case let .Add(x,y):
            return operateFieldAdd(x.eval(), y.eval())
        case let .Mul(x,y):
            return operateFieldMul(x.eval(), y.eval())
        case let .Quotient(l, r):
            return (l * ~r).eval()
        case let .Subtract(l, r):
            return (l + -r).eval()
        case let .Negate(x):
            return (Self._id * x).eval()
        case .Var(_):
            return self
        case let .Inverse(x):
            let x = x.eval()
            switch x.op.op {
            case let .Number(number):
                return OpSum.O.Number(~number).f
            case let .Quotient(numer, denom):
                return OpSum.O.Quotient(denom, numer).f.eval()
            case let .Inverse(x):
                return x.eval()
            default:
                return OpSum.O.Inverse(x).f
            }
        case .Power(base: let _base, exponent: let _exponent):
            let base = _base.eval()
            let exponent = _exponent.eval()
            if case let OpSum.O.Number(numExp) = exponent.op.op {
                if numExp == .zero {
                    return OpSum.O.Number(.id).f
                } else if numExp == .id {
                    return base
                } else if numExp == -.id {
                    return ~base
                }
                
                if case let OpSum.O.Number(numBase) = base.op.op {
                    if let evaled = numBase^numExp {
                        return OpSum.O.Number(evaled).f
                    }
                }
            }
            return OpSum.O.Power(base: base, exponent: exponent).f
        case let .Conjugate(xx):
            let x = xx.eval()
            switch x.op.op {
            case let OpSum.O.Number(n):
                return OpSum.O.Number(*n).f
            default:
                return OpSum.O.Conjugate(x).f
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
