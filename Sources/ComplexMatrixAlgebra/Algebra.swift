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
            if case let (.Number(l), .Number(r)) = (l,r) {
                return .Number(l * r)
            }
            return .Mul(l, r)
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
}

enum RealNumber: Equatable, FieldSet {
    static prefix func ~ (lhs: RealNumber) -> RealNumber {
        switch lhs {
        case let .N(n):
            return (RealNumber.Q(Rational(1, n))).eval()
        case let .Q(q):
            return RealNumber.Q(Rational(q.denominator, q.numerator)).eval()
        case let .R(r):
            return RealNumber.R(1/r).eval()
        }
    }
    
    static prefix func - (lhs: RealNumber) -> RealNumber {
        switch lhs {
        case let .N(n): return .N(-n)
        case let .Q(q): return .Q(-q)
        case let .R(r): return .R(-r)
        }
    }
    
    static func - (lhs: RealNumber, rhs: RealNumber) -> RealNumber {
        return lhs + (-rhs)
    }
    
    static func + (lhs: RealNumber, rhs: RealNumber) -> RealNumber {
        switch (lhs,rhs) {
        case let (.N(x), .N(y)): return (.N(x+y))

        case let (.N(x), .Q(y)): return (RealNumber.Q(y + Rational<Int>(x))).eval()
        case let (.Q(y), .N(x)): return (RealNumber.Q(y + Rational<Int>(x))).eval()

        case let (.N(x), .R(y)): return (RealNumber.R(y + Double(x))).eval()
        case let (.R(y), .N(x)): return (RealNumber.R(y + Double(x))).eval()

        case let (.Q(x), .Q(y)): return (RealNumber.Q(y + x)).eval()

        case let (.Q(x), .R(y)): return (RealNumber.R(x.doubleValue + y)).eval()
        case let (.R(y), .Q(x)): return (RealNumber.R(x.doubleValue + y)).eval()

        case let (.R(x), .R(y)): return (RealNumber.R(y + x)).eval()
        }
    }
    
    static var zero: RealNumber {return .N(0)}
    
    static var id: RealNumber {return .N(1)}
    
    func eval() -> RealNumber {
        switch self {
        case .N(_): return self
        case let .Q(q):
            if let n = q.intValue { return .N(n) }
            else                  { return self }
        case let .R(r):
            if abs(r - r.rounded()) < 0.00001 { return (.N(Int(r.rounded())))}
            else                              { return self }
        }
    }
    
    static func * (lhs: RealNumber, rhs: RealNumber) -> RealNumber {
        switch (lhs,rhs) {
        case let (.N(x), .N(y)): return (.N(x*y))

        case let (.N(x), .Q(y)): return (RealNumber.Q(y * Rational<Int>(x))).eval()
        case let (.Q(y), .N(x)): return (RealNumber.Q(y * Rational<Int>(x))).eval()

        case let (.N(x), .R(y)): return (RealNumber.R(y * Double(x))).eval()
        case let (.R(y), .N(x)): return (RealNumber.R(y * Double(x))).eval()

        case let (.Q(x), .Q(y)): return (RealNumber.Q(y * x)).eval()

        case let (.Q(x), .R(y)): return (RealNumber.R(x.doubleValue * y)).eval()
        case let (.R(y), .Q(x)): return (RealNumber.R(x.doubleValue * y)).eval()

        case let (.R(x), .R(y)): return (RealNumber.R(y * x)).eval()
        }
    }
    
    case N(Int)
    case Q(Rational<Int>)
    case R(Double)
}

typealias Real = FieldImp<RealNumber>
//indirect enum Real:Field {
//    func flatAdd() -> [Real] {
//        if case let .Add(x, y) = self {
//            return x.flatAdd() + y.flatAdd()
//        } else {
//            return [self]
//        }
//    }
//
//    func eval() -> Real {
//        switch self {
//        case let .Number(number):
//            switch number {
//            case .N(_): return self
//            case let .Q(q):
//                if let n = q.intValue { return .Number(.N(n)) }
//                else                  { return self }
//            case let .R(r):
//                if abs(r - r.rounded()) < 0.00001 { return .Number(.N(Int(r.rounded())))}
//                else                              { return self }
//            }
//        case let .Add(l, r):
//            let l = l.eval()
//            let r = r.eval()
//            if l == Real.zero {
//                return r
//            } else if r == Real.zero {
//                return l
//            } else if case let (.Number(l), .Number(r)) = (l,r) {
//                switch (l,r) {
//                case let (.N(x), .N(y)): return Real.Number(.N(x+y))
//
//                case let (.N(x), .Q(y)): return Real.Number(.Q(y + Rational<Int>(x))).eval()
//                case let (.Q(y), .N(x)): return Real.Number(.Q(y + Rational<Int>(x))).eval()
//
//                case let (.N(x), .R(y)): return Real.Number(.R(y + Double(x))).eval()
//                case let (.R(y), .N(x)): return Real.Number(.R(y + Double(x))).eval()
//
//                case let (.Q(x), .Q(y)): return Real.Number(.Q(y + x)).eval()
//
//                case let (.Q(x), .R(y)): return Real.Number(.R(x.doubleValue + y)).eval()
//                case let (.R(y), .Q(x)): return Real.Number(.R(x.doubleValue + y)).eval()
//
//                case let (.R(x), .R(y)): return Real.Number(.R(y + x)).eval()
//                }
//            } else {
//                let flatten = l.flatAdd() + r.flatAdd()
//                let (numbers, nonNumbers) = flatten.seperate({if case .Number(_) = $0 {return true} else {return false}})
//                let addedNumbers = numbers.reduce(Real.zero, +).eval()
//                return nonNumbers.reduce(addedNumbers, +)
//            }
//        case let .Mul(l, r):
//            let l = l.eval()
//            let r = r.eval()
//            if case let (.Number(l), .Number(r)) = (l,r) {
//                switch (l,r) {
//                case let (.N(x), .N(y)): return Real.Number(.N(x*y))
//
//                case let (.N(x), .Q(y)): return Real.Number(.Q(y * Rational<Int>(x))).eval()
//                case let (.Q(y), .N(x)): return Real.Number(.Q(y * Rational<Int>(x))).eval()
//
//                case let (.N(x), .R(y)): return Real.Number(.R(y * Double(x))).eval()
//                case let (.R(y), .N(x)): return Real.Number(.R(y * Double(x))).eval()
//
//                case let (.Q(x), .Q(y)): return Real.Number(.Q(y * x)).eval()
//
//                case let (.Q(x), .R(y)): return Real.Number(.R(x.doubleValue * y)).eval()
//                case let (.R(y), .Q(x)): return Real.Number(.R(x.doubleValue * y)).eval()
//
//                case let (.R(x), .R(y)): return Real.Number(.R(y * x)).eval()
//                }
//            }
//            return .Mul(l, r)
//        case let .Div(l, r):
//            return (l * ~r).eval()
//        case let .Subtract(l, r):
//            return (l + -r).eval()
//        case let .Negate(x):
//            return (.Number(.N(-1)) * x).eval()
//        case .Var(_):
//            return self
//        case let .Inverse(x):
//            let x = x.eval()
//            switch x {
//            case let .Number(number):
//                switch number {
//                case let .N(n):
//                    return Real.Number(.Q(Rational(1, n))).eval()
//                case let .Q(q):
//                    return Real.Number(.Q(Rational(q.denominator, q.numerator))).eval()
//                case let .R(r):
//                    return Real.Number(.R(1/r)).eval()
//                }
//            case let .Div(numer, denom):
//                return Real.Div(denom, numer).eval()
//            case let .Inverse(x):
//                return x.eval()
//            default:
//                return .Inverse(x)
//            }
//        }
//    }
//
//    static prefix func ~ (lhs: Real) -> Real { return .Inverse(lhs) }
//    static prefix func - (lhs: Real) -> Real { return .Negate(lhs) }
//    static func + (lhs: Real, rhs: Real) -> Real { return .Add(lhs, rhs) }
//    static func - (lhs: Real, rhs: Real) -> Real { return .Subtract(lhs, rhs) }
//    static func * (lhs: Real, rhs: Real) -> Real { return .Mul(lhs, rhs) }
//    static var zero: Real { return .Number(.N(0)) }
//    static var id: Real { return .Number(.N(1)) }
//    static func / (lhs: Real, rhs: Real) -> Real { return .Div(lhs, rhs) }
//
//    case Number(RealNumber)
//    case Add(Real, Real)
//    case Mul(Real, Real)
//    case Div(Real, Real)
//    case Subtract(Real, Real)
//    case Negate(Real)
//    case Var(String)
//    case Inverse(Real)
//
//}
