//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation

struct ComplexNumber: FieldSet {
    static func / (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
        //compiling never ends
        let a1 = lhs.r
        let b1 = lhs.i
        let a2 = rhs.r
        let b2 = rhs.i
        let a1a2 = a1 * a2
        let b1b2 = b1 * b2
        let a22 = a2 * a2
        let b22 = b2 * b2
        let a22_b22 = a22 + b22
        let b1a2 = b1 * a2
        let a1b2 = a1 * b2
        let r = (a1a2 + b1b2) / a22_b22
        let i = (b1a2 - a1b2) / a22_b22
        return ComplexNumber(r: r, i: i).eval()
    }
    
    
    static prefix func ~ (lhs: ComplexNumber) -> ComplexNumber {
        return (lhs.conjugate / (lhs * lhs.conjugate)).eval()
    }
    
    var conjugate:ComplexNumber {
        return ComplexNumber(r: r, i: -i).eval()
    }
    static prefix func - (lhs: ComplexNumber) -> ComplexNumber {
        return ComplexNumber(r: -lhs.r, i: -lhs.i).eval()
    }
    
    static func - (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
        return ComplexNumber(r: lhs.r - rhs.r, i: lhs.i - rhs.i).eval()
    }
    
    static func + (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
        return ComplexNumber(r: lhs.r + rhs.r, i: lhs.i + rhs.i).eval()
    }
    
    let r:Real
    let i:Real

    static var zero: ComplexNumber {
        return ComplexNumber(r: Real.zero, i: Real.zero)
    }
    
    static var id: ComplexNumber {
        return ComplexNumber(r: Real.id, i: Real.zero)
    }
    
    func eval() -> ComplexNumber {
        ComplexNumber(r: r.eval(), i: i.eval())
    }
    
    static func * (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
        let img = (lhs.r * rhs.i) + (lhs.i * rhs.r)
        let real = (lhs.r * rhs.r) - (lhs.i * rhs.i)
        return ComplexNumber(r: real, i: img).eval()
    }
    
}

//struct ComplexNumber: Equatable {
//    let i: Real
//    let real: Real
//}
//struct ComplexBinary: BinaryOperator {
//    let l: Complex
//    let r: Complex
//}
//
//indirect enum Complex: Algebra {
//    case Number(ComplexNumber)
//    case Add(ComplexBinary)
//    case Mul(ComplexBinary)
//    
//    static func == (lhs: Complex, rhs: Complex) -> Bool {
//        switch lhs {
//        case let .Number(l):
//            guard case let .Number(r) = rhs else { return false }
//            return l == r
//        case let .Add(l):
//            guard case let .Add(r) = rhs else { return false }
//            return l.eq(r)
//        case let .Mul(l):
//            guard case let .Mul(r) = rhs else { return false }
//            return l.eq(r)
//        }
//    }
//    
//    func eval() -> Complex {
//        switch self {
//        case let .Number(x):
//            let i = x.i.eval()
//            let r = x.real.eval()
//            return .Number(ComplexNumber(i: i, real: r))
//        case let .Add(x):
//            let l = x.l.eval()
//            let r = x.r.eval()
//            
//            if case let .Number(l) = l, case let .Number(r) = r{
//                let img = Real.Add(RealBinary(l: l.i, r: r.i))
//                let real = Real.Add(RealBinary(l: l.real, r: r.real))
//                return Complex.Number(ComplexNumber(i: img, real: real)).eval()
//            }
//            
//            return .Add(ComplexBinary(l: l, r: r))
//        case let .Mul(x):
//            let l = x.l.eval()
//            let r = x.r.eval()
//            
//            if case let .Number(l) = l, case let .Number(r) = r {
//                let img = Real.Add(RealBinary(
//                    l: .Mul(RealBinary(l: l.i, r: r.real)),
//                    r: .Mul(RealBinary(l: l.real, r: r.i))))
//                let real = Real.Subtract(RealBinary(
//                    l: .Mul(RealBinary(l: l.real, r: r.real)),
//                    r: .Mul(RealBinary(l: l.i, r: r.i))))
//                return Complex.Number(ComplexNumber(i: img, real: real)).eval()
//            }
//            
//            return .Mul(ComplexBinary(l: l, r: r))
//        }
//    }
//    
//    func iso(_ to: Complex) -> Bool {
//        switch self {
//        case let .Number(l):
//            guard case let .Number(r) = to else { return false }
//            return l == r
//        case let .Add(l):
//            guard case let .Add(r) = to else { return false }
//            return l.commutativeIso(r)
//        case let .Mul(l):
//            guard case let .Mul(r) = to else { return false }
//            return l.commutativeIso(r)
//        }
//    }
//    
//}
