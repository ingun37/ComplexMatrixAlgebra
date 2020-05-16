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
        case let (.Add(x), .Add(y)):
            return commuteSame(x.flat().all, y.flat().all)
        case let (.Mul(x), .Mul(y)):
            return commuteSame(x.flat().all, y.flat().all)
        default:
            return self == to
        }
    }
    
    
    case Number(Num)
    case Add(FAdd<Num>)
    case Mul(FMul<Num>)
    case Quotient(Field, Field)
    case Subtract(Field, Field)
    case Negate(Field)
    case Var(String)
    case Inverse(Field)
    case Power(base:Field, exponent:Field)
    static prefix func ~ (lhs: Field<Num>) -> Field<Num> { return .Inverse(lhs) }
    static prefix func - (lhs: Field<Num>) -> Field<Num> { return .Negate(lhs) }
    static func - (lhs: Field<Num>, rhs: Field<Num>) -> Field<Num> { return .Subtract(lhs, rhs) }
    static func + (lhs: Field<Num>, rhs: Field<Num>) -> Field<Num> { return .Add(FAdd(lhs, rhs)) }
    static var zero: Field<Num> { return .Number(Num.zero)}
    static var id: Field<Num>{ return .Number(Num.id)}
    static func / (lhs: Field<Num>, rhs: Field<Num>) -> Field<Num> { return .Quotient(lhs, rhs) }
    static func * (lhs: Field<Num>, rhs: Field<Num>) -> Field<Num> { return .Mul(FMul(lhs, rhs)) }
    static func ^ (lhs: Field<Num>, rhs: Field<Num>) -> Field<Num> { return .Power(base: lhs, exponent: rhs) }

    func eval() -> Field<Num> {
        switch self {
        case let .Number(number): return .Number(number.eval())
        case let .Add(pair):
            return pair.eval()
        case let .Mul(pair):
            return pair.eval()
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

}

protocol FieldBinary:Equatable {
    associatedtype Num:FieldSet
    typealias A = Field<Num>
    var l: A {get}
    var r: A {get}
    static func match(_ a:A)->Self?
    static func tryCollapse(_ l:A, _ r:A)-> A?
    static func operation(lhs:A, rhs:A)-> A
    init(_ l:A, _ r:A)
}
extension FieldBinary {
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
struct FAdd<Num:FieldSet>:FieldBinary {
    static func operation(lhs: A, rhs: A) -> A {
        return lhs + rhs
    }
    
    typealias A = Field<Num>
    static func tryCollapse(_ l: A, _ r: A) -> A? {
        if l == A.zero {
            return r
        } else if case let (.Number(l), .Number(r)) = (l,r) {
            return .Number(l + r)
        } else {
            return nil
        }
    }
    
    static func match(_ a: Field<Num>) -> FAdd<Num>? {
        if case let .Add(x) = a {
            return x
        } else {
            return nil
        }
    }
    
    let l: Field<Num>
    let r: Field<Num>
    init(_ l:A, _ r:A) {
        self.l = l
        self.r = r
    }
}
struct FMul<Num:FieldSet>:FieldBinary {
    static func operation(lhs: A, rhs: A) -> A {
        return lhs * rhs
    }
    
    typealias A = Field<Num>
    static func tryCollapse(_ l: A, _ r: A) -> A? {
        if case let .Add(xy) = l {
            let xr = xy.l * r
            let yr = xy.r * r
            return (xr + yr).eval()
        } else if l == A.id {
            return r
        } else if l == A.zero {
            return A.zero
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
    
    static func match(_ a: Field<Num>) -> FMul<Num>? {
        if case let .Mul(x) = a {
            return x
        } else {
            return nil
        }
    }
    
    let l: Field<Num>
    let r: Field<Num>
    init(_ l:A, _ r:A) {
        self.l = l
        self.r = r
    }
}
