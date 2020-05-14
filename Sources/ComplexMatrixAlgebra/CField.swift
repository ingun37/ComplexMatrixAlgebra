//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation


struct ComplexNumber: Equatable {
    let i: Real
    let real: Real
}
struct ComplexBinary: AlgebraBinaryOperator {
    let l: ComplexField
    let r: ComplexField
}

indirect enum ComplexField: Algebra {
    static func == (lhs: ComplexField, rhs: ComplexField) -> Bool {
        switch lhs {
        case let .Number(l):
            guard case let .Number(r) = rhs else { return false }
            return l == r
        case let .Add(l):
            guard case let .Add(r) = rhs else { return false }
            return l.eq(r)
        case let .Mul(l):
            guard case let .Mul(r) = rhs else { return false }
            return l.eq(r)
        }
    }
    
    case Number(ComplexNumber)
    case Add(ComplexBinary)
    case Mul(ComplexBinary)
    
    func eval() -> ComplexField {
        switch self {
        case let .Number(x):
            let i = x.i.eval()
            let r = x.real.eval()
            return .Number(ComplexNumber(i: i, real: r))
        case let .Add(x):
            let l = x.l.eval()
            let r = x.r.eval()
            
            if case let .Number(l) = l, case let .Number(r) = r{
                let img = Real.Add(RealBinary(l: l.i, r: r.i))
                let real = Real.Add(RealBinary(l: l.real, r: r.real))
                return ComplexField.Number(ComplexNumber(i: img, real: real))
            }
            
            return .Add(ComplexBinary(l: l, r: r))
        case let .Mul(x):
            let l = x.l.eval()
            let r = x.r.eval()
            
            if case let .Number(l) = l, case let .Number(r) = r {
                let img = Real.Add(RealBinary(
                    l: .Mul(RealBinary(l: l.i, r: r.real)),
                    r: .Mul(RealBinary(l: l.real, r: r.i))))
                let real = Real.Subtract(RealBinary(
                    l: .Mul(RealBinary(l: l.real, r: r.real)),
                    r: .Mul(RealBinary(l: l.i, r: r.i))))
                return ComplexField.Number(ComplexNumber(i: img, real: real)).eval()
            }
            
            return .Mul(ComplexBinary(l: l, r: r))
        }
    }
    
    func iso(_ to: ComplexField) -> Bool {
        switch self {
        case let .Number(l):
            guard case let .Number(r) = to else { return false }
            return l == r
        case let .Add(l):
            guard case let .Add(r) = to else { return false }
            return l.iso(r)
        case let .Mul(l):
            guard case let .Mul(r) = to else { return false }
            return l.iso(r)
        }
    }
    
}
