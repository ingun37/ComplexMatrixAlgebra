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
    static prefix func - (lhs: Self) -> Self
    static prefix func ~ (lhs: Self) -> Self
}

indirect enum FieldImp<Num>: Field where Num:FieldSet{
    case Number(Num)
    case Add(FieldImp, FieldImp)
    case Mul(FieldImp, FieldImp)
    case Div(FieldImp, FieldImp)
    case Subtract(FieldImp, FieldImp)
    case Negate(FieldImp)
    case Var(String)
    case Inverse(FieldImp)
    
    static prefix func ~ (lhs: FieldImp<Num>) -> FieldImp<Num> { return .Inverse(lhs) }
    static prefix func - (lhs: FieldImp<Num>) -> FieldImp<Num> { return .Negate(lhs) }
    static func - (lhs: FieldImp<Num>, rhs: FieldImp<Num>) -> FieldImp<Num> { return .Subtract(lhs, rhs) }
    static func + (lhs: FieldImp<Num>, rhs: FieldImp<Num>) -> FieldImp<Num> { return .Add(lhs, rhs) }
    static var zero: FieldImp<Num> { return .Number(Num.zero)}
    static var id: FieldImp<Num>{ return .Number(Num.id)}
    static func / (lhs: FieldImp<Num>, rhs: FieldImp<Num>) -> FieldImp<Num> { return .Div(lhs, rhs) }
    static func * (lhs: FieldImp<Num>, rhs: FieldImp<Num>) -> FieldImp<Num> { return .Mul(lhs, rhs) }

    func eval() -> FieldImp<Num> {
        switch self {
        case let .Number(number): return .Number(number.eval())
        case let .Add(l, r):
            let l = l.eval()
            let r = r.eval()
            if l == Self.zero {
                return r
            } else if r == Self.zero {
                return l
            } else if case let (.Number(l), .Number(r)) = (l,r) {
                return .Number(l + r)
            } else {
                let flatten = l.flatAdd() + r.flatAdd()
                let (numbers, nonNumbers) = flatten.seperate({if case .Number(_) = $0 {return true} else {return false}})
                let addedNumbers = numbers.reduce(Self.zero, +).eval()
                return nonNumbers.reduce(addedNumbers, +)
            }
        case let .Mul(l, r):
            let l = l.eval()
            let r = r.eval()
            if l == Self.id {
                return r
            } else if r == Self.id {
                return l
            } else if case let (.Number(l), .Number(r)) = (l,r) {
                return .Number(l * r)
            } else {
                let flatten = l.flatMul() + r.flatMul()
                let (numbers, nonNumbers) = flatten.seperate({if case .Number(_) = $0 {return true} else {return false}})
                let multipliedNumbers = numbers.reduce(Self.id, *).eval()
                return nonNumbers.reduce(multipliedNumbers, *)
            }
        case let .Div(l, r):
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
            case let .Div(numer, denom):
                return FieldImp<Num>.Div(denom, numer).eval()
            case let .Inverse(x):
                return x.eval()
            default:
                return .Inverse(x)
            }
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

