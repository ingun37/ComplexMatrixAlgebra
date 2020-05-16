//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/16.
//

import Foundation


protocol FieldSet: Equatable {
    static var zero: Self {get}
    static var id: Self {get}
    func eval() -> Self
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
    static prefix func - (lhs: Self) -> Self
    static prefix func ~ (lhs: Self) -> Self
    static func ^ (lhs: Self, rhs: Self) -> Self?
}



extension FieldSet {
    static func ^ (lhs: Self, rhs: Int) -> Self {
        if rhs == 0 {
            return id
        } else if rhs < 0 {
            let inv = ~lhs
            return (rhs+1..<0).map({_ in inv}).reduce(inv, *).eval()
        } else {
            return (1..<rhs).map({_ in lhs}).reduce(lhs, *).eval()
        }
    }
}
indirect enum Field<Num>: Algebra where Num:FieldSet{
    func same(_ to: Field<Num>) -> Bool {
        switch (self, to) {
        case (.Add(_, _), .Add(_, _)):
            return commuteSame(self.flatAdd().all, to.flatAdd().all)
        case (.Mul(_, _), .Mul(_, _)):
            return commuteSame(self.flatMul().all, to.flatMul().all)
        default:
            return self == to
        }
    }
    
    
    case Number(Num)
    case Add(Field, Field)
    case Mul(Field, Field)
    case Quotient(Field, Field)
    case Subtract(Field, Field)
    case Negate(Field)
    case Var(String)
    case Inverse(Field)
    case Power(base:Field, exponent:Field)
    static prefix func ~ (lhs: Field<Num>) -> Field<Num> { return .Inverse(lhs) }
    static prefix func - (lhs: Field<Num>) -> Field<Num> { return .Negate(lhs) }
    static func - (lhs: Field<Num>, rhs: Field<Num>) -> Field<Num> { return .Subtract(lhs, rhs) }
    static func + (lhs: Field<Num>, rhs: Field<Num>) -> Field<Num> { return .Add(lhs, rhs) }
    static var zero: Field<Num> { return .Number(Num.zero)}
    static var id: Field<Num>{ return .Number(Num.id)}
    static func / (lhs: Field<Num>, rhs: Field<Num>) -> Field<Num> { return .Quotient(lhs, rhs) }
    static func * (lhs: Field<Num>, rhs: Field<Num>) -> Field<Num> { return .Mul(lhs, rhs) }
    static func ^ (lhs: Field<Num>, rhs: Field<Num>) -> Field<Num> { return .Power(base: lhs, exponent: rhs) }

    func eval() -> Field<Num> {
        switch self {
        case let .Number(number): return .Number(number.eval())
        case let .Add(_l, _r):
            let l = _l.eval()
            let r = _r.eval()
            let flatten = (l.flatAdd() + r.flatAdd())
            let best = edgeMerge(_objs: flatten) { (l, r) in
                if l == Self.zero {
                    return r
                } else if r == Self.zero {
                    return l
                } else if case let (.Number(l), .Number(r)) = (l,r) {
                    return .Number(l + r)
                }
                return nil
            }
            return best.tail.reduce(best.head, +)
        case let .Mul(_l, _r):
            let l = _l.eval()
            let r = _r.eval()
            
            if case let .Add(x,y) = l {
                let xr = x * r
                let yr = y * r
                return (xr + yr).eval()
            } else if case let .Add(x,y) = r {
               let lx = l * x
               let ly = l * y
               return (lx + ly).eval()
            } else {
                let flatten = l.flatMul() + r.flatMul()
                let bestEffort = edgeMerge(_objs: flatten) { (l, r) in
                    
                    if let symmetric = tryMul(l, r) {
                        return symmetric
                    } else if let symmetric = tryMul(r, l) {
                        return symmetric
                    } else {
                        return nil
                    }
                }
                return bestEffort.tail.reduce(bestEffort.head, *)
            }
        case let .Quotient(l, r):
            return (l * ~r).eval()
        case let .Subtract(l, r):
            return (l + -r).eval()
        case let .Negate(x):
            return (.Number(-Num.id) * x).eval()
        case .Var(_):
            return self
        case let .Inverse(x):
            let x = x.eval()
            switch x {
            case let .Number(number):
                return .Number(~number)
            case let .Quotient(numer, denom):
                return Field<Num>.Quotient(denom, numer).eval()
            case let .Inverse(x):
                return x.eval()
            default:
                return .Inverse(x)
            }
        case .Power(base: let _base, exponent: let _exponent):
            let base = _base.eval()
            let exponent = _exponent.eval()
            if case let .Number(numExp) = exponent {
                if numExp == .zero {
                    return .Number(.id)
                } else if numExp == .id {
                    return base
                } else if numExp == -.id {
                    return ~base
                }
                
                if case let .Number(numBase) = base {
                    if let evaled = numBase^numExp {
                        return .Number(evaled)
                    }
                }
            }
            return .Power(base: base, exponent: exponent)
        }
    }
    
    func flatAdd() -> List<Field<Num>> {
        if case let .Add(x, y) = self {
            let x = x.flatAdd()
            let y = y.flatAdd()
            return List(x.head, x.tail + [y.head] + y.tail)
        } else {
            return List(self,[])
        }
    }
    
    func flatMul() -> List<Field<Num>> {
        if case let .Mul(x, y) = self {
            let x = x.flatMul()
            let y = y.flatMul()
            return List(x.head, x.tail + [y.head] + y.tail)
        } else {
            return List(self, [])
        }
    }
    func tryMul(_ l:Field<Num>, _ r:Field<Num>) -> Field<Num>? {
        if l == Self.id {
            return r
        } else if l == Self.zero {
            return Self.zero
        } else if case let (.Number(ln), .Number(rn)) = (l,r) {
            return Field<Num>.Number(ln * rn).eval()
        }
        switch (l,r) {
        case (.Power(base: let lbase, exponent: let lexp), .Power(base: let rbase, exponent: let rexp)):
            if lbase.same(rbase) {
                return Field<Num>.Power(base: lbase, exponent: lexp + rexp).eval()
            }
        default:
            return nil
        }
        return nil
    }

}
