//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit

//TODO: Change once accepted: https://forums.swift.org/t/accepted-se-0280-enum-cases-as-protocol-witnesses/34850
protocol Algebra: Equatable {
    func eval() -> Self
    func same(_ to:Self)-> Bool
}

protocol AbelianGroup:Algebra {
    associatedtype BinaryOp:AbelianGroupBinary where BinaryOp.A == Self //Add or Mul?
    var asBinary: BinaryOp? { get }
}
protocol AbelianGroupBinary {
    associatedtype A:AbelianGroup where A.BinaryOp == Self
    var l: A { get }
    var r: A { get }
    static var id:A {get}
}
struct TempCodable<T:AbelianGroup>:Codable&Equatable {
    func encode(to encoder: Encoder) throws { }
    init(from decoder: Decoder) throws { self.x = T.BinaryOp.id }
    init(_ x:T) {
        self.x = x
    }
    let x:T
}
extension AbelianGroupBinary {
    func flatten() -> (A,[A]) {
        let (lh,lt) = l.asBinary?.flatten() ?? (l,[])
        let (rh,rt) = r.asBinary?.flatten() ?? (r,[])
        return (lh, lt + [rh] + rt)
    }
    
}



protocol Field: Algebra {
    
    static var zero:Self {get}
    
    /**
     multiplicative id
     */
    static var id:Self {get}
    static func / (lhs: Self, rhs: Self) -> Self
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static prefix func - (lhs: Self) -> Self
    static prefix func ~ (lhs: Self) -> Self
    
}

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


func commuteSame<C:Collection, T:Algebra>(_ xs:C, _ ys:C) -> Bool where C.Element == T, C.Index == Int{
    guard xs.count == ys.count else { return false }
    let len = xs.count
    if len == 0 { return true }
    let aa = (0..<len).flatMap({i in (0..<len).map({(i,$0)})})
    if let match = aa.first(where: { xs[$0].same(ys[$1]) }) {
        return commuteSame(xs.without(at:match.0), ys.without(at: match.1))
    } else {
        return false
    }
    
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
indirect enum FieldImp<Num>: Field where Num:FieldSet{
    func same(_ to: FieldImp<Num>) -> Bool {
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
    case Add(FieldImp, FieldImp)
    case Mul(FieldImp, FieldImp)
    case Quotient(FieldImp, FieldImp)
    case Subtract(FieldImp, FieldImp)
    case Negate(FieldImp)
    case Var(String)
    case Inverse(FieldImp)
    case Power(base:FieldImp, exponent:FieldImp)
    static prefix func ~ (lhs: FieldImp<Num>) -> FieldImp<Num> { return .Inverse(lhs) }
    static prefix func - (lhs: FieldImp<Num>) -> FieldImp<Num> { return .Negate(lhs) }
    static func - (lhs: FieldImp<Num>, rhs: FieldImp<Num>) -> FieldImp<Num> { return .Subtract(lhs, rhs) }
    static func + (lhs: FieldImp<Num>, rhs: FieldImp<Num>) -> FieldImp<Num> { return .Add(lhs, rhs) }
    static var zero: FieldImp<Num> { return .Number(Num.zero)}
    static var id: FieldImp<Num>{ return .Number(Num.id)}
    static func / (lhs: FieldImp<Num>, rhs: FieldImp<Num>) -> FieldImp<Num> { return .Quotient(lhs, rhs) }
    static func * (lhs: FieldImp<Num>, rhs: FieldImp<Num>) -> FieldImp<Num> { return .Mul(lhs, rhs) }
    static func ^ (lhs: FieldImp<Num>, rhs: FieldImp<Num>) -> FieldImp<Num> { return .Power(base: lhs, exponent: rhs) }

    func eval() -> FieldImp<Num> {
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
                return FieldImp<Num>.Quotient(denom, numer).eval()
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
    
    func flatAdd() -> List<FieldImp<Num>> {
        if case let .Add(x, y) = self {
            let x = x.flatAdd()
            let y = y.flatAdd()
            return List(x.head, x.tail + [y.head] + y.tail)
        } else {
            return List(self,[])
        }
    }
    
    func flatMul() -> List<FieldImp<Num>> {
        if case let .Mul(x, y) = self {
            let x = x.flatMul()
            let y = y.flatMul()
            return List(x.head, x.tail + [y.head] + y.tail)
        } else {
            return List(self, [])
        }
    }
    func tryMul(_ l:FieldImp<Num>, _ r:FieldImp<Num>) -> FieldImp<Num>? {
        if l == Self.id {
            return r
        } else if l == Self.zero {
            return Self.zero
        } else if case let (.Number(ln), .Number(rn)) = (l,r) {
            return FieldImp<Num>.Number(ln * rn).eval()
        }
        switch (l,r) {
        case (.Power(base: let lbase, exponent: let lexp), .Power(base: let rbase, exponent: let rexp)):
            if lbase.same(rbase) {
                return FieldImp<Num>.Power(base: lbase, exponent: lexp + rexp).eval()
            }
        default:
            return nil
        }
        return nil
    }

}
