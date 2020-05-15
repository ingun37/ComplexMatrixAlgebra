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
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static prefix func - (lhs: Self) -> Self
    static prefix func ~ (lhs: Self) -> Self
    
    func flatAdd() -> [Self]
}

protocol Field: Algebra {
    
    static var zero:Self {get}
    
    /**
     multiplicative id
     */
    static var id:Self {get}
    static func / (lhs: Self, rhs: Self) -> Self
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
    struct Cod:Codable&Equatable {
        func encode(to encoder: Encoder) throws { }
        init(from decoder: Decoder) throws { self.x = .Number(.id) }
        init(_ x:FieldImp<Num>) {
            self.x = x
        }
        let x:FieldImp<Num>
        
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
            let flatten = l.flatAdd() + r.flatAdd()
            let flatCodables = flatten.map({Cod($0)})
            let addedBestEffort = edgeMerge(objs: flatCodables) { (_l, _r) -> Cod? in
                let l = _l.x
                let r = _r.x
                if l == Self.zero {
                    return Cod(r)
                } else if r == Self.zero {
                    return Cod(l)
                } else if case let (.Number(l), .Number(r)) = (l,r) {
                    return Cod(.Number(l + r))
                }
                return nil
            }.map({$0.x})
            if let head = addedBestEffort.first {
                return addedBestEffort.dropFirst().reduce(head, +)
            } else {
                fatalError()
            }
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
                let flatCodable = flatten.map({Cod($0)})
                let bestEffort = edgeMerge(objs: flatCodable) { (_l, _r) -> Cod? in
                    let l = _l.x
                    let r = _r.x
                    
                    if l == Self.id {
                        return Cod(r)
                    } else if r == Self.id {
                        return Cod(l)
                    } else if l == Self.zero {
                        return Cod(Self.zero)
                    } else if r == Self.zero {
                        return Cod(Self.zero)
                    } else if case let (.Number(ln), .Number(rn)) = (l,r) {
                        return Cod(.Number(ln * rn))
                    }
                    return nil
                }.map({$0.x})
                if let head = bestEffort.first {
                    return bestEffort.dropFirst().reduce(head, *)
                } else {
                    fatalError()
                }
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
    
    func flatAdd() -> [FieldImp<Num>] {
        if case let .Add(x, y) = self {
            return x.flatAdd() + y.flatAdd()
        } else {
            return [self]
        }
    }
    
    func flatMul() -> [FieldImp<Num>] {
        if case let .Mul(x, y) = self {
            return x.flatMul() + y.flatMul()
        } else {
            return [self]
        }
    }
}
