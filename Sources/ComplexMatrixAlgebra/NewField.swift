//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/18.
//

import Foundation

protocol _Field:Algebra where OperatorSum == FieldOperators<Self, Num> {
    associatedtype Num:FieldSet
    
    

}


indirect enum FieldOperators<F:Equatable,Num:FieldSet>:Equatable {
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

extension FieldOperators where F:_Field, F.Num == Num {
    var f: F {
        return F(op: self)
    }
}
prefix operator *
extension _Field {
    func same(_ to: Self) -> Bool {
        switch (op, to.op) {
        case let (.Add(xl,xr), .Add(yl,yr)):
            let x = _FAdd(xl, xr)
            let y = _FAdd(yl, yr)
            return commuteSame(x.flat().all, y.flat().all)
        case let (.Mul(xl,xr), .Mul(yl,yr)):
            let x = _FMul(xl, xr)
            let y = _FMul(yl, yr)
            return commuteSame(x.flat().all, y.flat().all)
        default:
            return self == to
        }
    }
    static prefix func ~ (lhs: Self) -> Self { return Self(op:.Inverse(lhs)) }
    static prefix func - (lhs: Self) -> Self { return Self(op:.Negate(lhs)) }
    static prefix func * (lhs: Self) -> Self { return Self(op:.Conjugate(lhs)) }

    static func - (lhs: Self, rhs: Self) -> Self { return Self(op:.Subtract(lhs, rhs)) }
    static func + (lhs: Self, rhs: Self) -> Self { return Self(op:.Add(lhs, rhs)) }
    static var zero: Self { return Self(op:.Number(Num.zero))}
    static var id: Self{ return Self(op:.Number(Num.id))}
    static var _id: Self{ return Self(op:.Number(-Num.id))}
    static func / (lhs: Self, rhs: Self) -> Self { return Self(op:.Quotient(lhs, rhs)) }
    static func * (lhs: Self, rhs: Self) -> Self { return Self(op:.Mul(lhs, rhs)) }
    static func ^ (lhs: Self, rhs: Self) -> Self { return Self(op:.Power(base: lhs, exponent: rhs)) }
    
    func eval() -> Self {
        switch op {
        case let .Number(number): return Self(op:.Number(number.eval()))
        case let .Add(x,y):
            return _FAdd(x,y).eval()
        case let .Mul(x,y):
            return _FMul(x,y).eval()
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
            switch x.op {
            case let .Number(number):
                return Self(op:.Number(~number))
            case let .Quotient(numer, denom):
                return Self(op:.Quotient(denom, numer)).eval()
            case let .Inverse(x):
                return x.eval()
            default:
                return Self(op:.Inverse(x))
            }
        case .Power(base: let _base, exponent: let _exponent):
            let base = _base.eval()
            let exponent = _exponent.eval()
            if case let .Number(numExp) = exponent.op {
                if numExp == .zero {
                    return OperatorSum.Number(.id).f
                } else if numExp == .id {
                    return base
                } else if numExp == -.id {
                    return ~base
                }
                
                if case let .Number(numBase) = base.op {
                    if let evaled = numBase^numExp {
                        return OperatorSum.Number(evaled).f
                    }
                }
            }
            return OperatorSum.Power(base: base, exponent: exponent).f
        case let .Conjugate(xx):
            let x = xx.eval()
            switch x.op {
            case let .Number(n):
                return OperatorSum.Number(*n).f
            default:
                return OperatorSum.Conjugate(x).f
            }
        }
    }
}


protocol _ACBinary:Equatable {
    associatedtype A:_Field
    var l: A {get}
    var r: A {get}
    static func match(_ a:A)->Self?
    static func tryCollapse(_ l:A, _ r:A)-> A?
    static func operation(lhs:A, rhs:A)-> A
    init(_ l:A, _ r:A)
}

extension _ACBinary {
    func flat() -> List<A> {
        let lll = Self.match(l)?.flat() ?? List(l, [])
        let rrr = Self.match(r)?.flat() ?? List(r, [])
        return lll + rrr
    }
    func eval() -> A {
        let l = self.l.eval()
        let r = self.r.eval()
        let flatten = Self(l, r).flat()
        let best = edgeMerge(_objs: flatten) { (l, r) in
            if let symmetric = Self.tryCollapse(l, r) {
                return symmetric
            } else if let symmetric = Self.tryCollapse(r, l) {
                return symmetric
            } else {
                return nil
            }
        }
        return best.tail.reduce(best.head, Self.operation)
    }
}

struct _FAdd<A:_Field>:_ACBinary {
    static func operation(lhs: A, rhs: A) -> A {
        return lhs + rhs
    }
    
    static func tryCollapse(_ l: A, _ r: A) -> A? {
        if l == A.zero {
            return r
        } else if case let (.Number(l), .Number(r)) = (l.op,r.op) {
            return A(op:.Number(l + r))
        } else if (-l).eval().same(r) {
            return A.zero
        } else {
            return nil
        }
    }
    
    static func match(_ a: A) -> _FAdd? {
        if case let A.OperatorSum.Add(xl,xr) = a.op {
            return _FAdd(xl,xr)
        } else {
            return nil
        }
    }
    
    let l: A
    let r: A
    init(_ l:A, _ r:A) {
        self.l = l
        self.r = r
    }
}
struct _FMul<A:_Field>:_ACBinary {
    static func operation(lhs: A, rhs: A) -> A {
        return lhs * rhs
    }
    
    typealias A = A
    static func tryCollapse(_ l: A, _ r: A) -> A? {
        if case let .Add(x, y) = l.op {
            let xr = x * r
            let yr = y * r
            return (xr + yr).eval()
        } else if l == A.id {
            return r
        } else if l == A.zero {
            return A.zero
        } else if case let (.Number(ln), .Number(rn)) = (l.op,r.op) {
            return A(op: A.OperatorSum.Number(ln * rn)).eval()
        }
        switch (l.op,r.op) {
        case (.Power(base: let lbase, exponent: let lexp), .Power(base: let rbase, exponent: let rexp)):
            if lbase.same(rbase) {
                return A(op: A.OperatorSum.Power(base: lbase, exponent: lexp + rexp)).eval()
            }
        default:
            return nil
        }
        return nil
    }
    
    static func match(_ a: A) -> _FMul? {
        if case let A.OperatorSum.Mul(xl,xr) = a.op {
            return _FMul(xl, xr)
        } else {
            return nil
        }
    }
    
    let l: A
    let r: A
    init(_ l:A, _ r:A) {
        self.l = l
        self.r = r
    }
}

