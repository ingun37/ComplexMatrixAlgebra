//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/15.
//

import Foundation

func genLaTex<T>(_ x:Field<T>) -> String {
    switch x {
    case let .Number(num):
        if let num = num as? RealNumber {
            switch num {
            case let .N(n):
                return n.description
            case let .Q(q):
                return "{\(q.numerator.description) \\over \(q.denominator.description)}"
            case let .R(r):
                return r.description
            }
        } else if let num = num as? ComplexNumber {
            return "\(wrappedLatex(num.r)) + \(wrappedLatex(num.i)) i"
        } else {
            return "unknown"
        }
    case let .Add(l,r):
        return "\(wrappedLatex(l)) + \(wrappedLatex(r))"
    case let .Mul(l, r):
        if let (l,r) = (l,r) as? (Real, Real){
            if case let (.Number(.N(ln)),r) = (l,r) {
                if ln == -1 {
                    return "-\(wrappedLatex(r))"
                }
            }
            if case let (l,.Number(.N(rn))) = (l,r) {
                if rn == -1 {
                    return "-\(wrappedLatex(l))"
                }
            }
        }
        return "\(wrappedLatex(l)) \\times \(wrappedLatex(r))"
        
    case let .Quotient(l, r):
        return "\\frac{\(genLaTex(l))}{\(genLaTex(r))}"
    case let .Subtract(l, r):
        return "\(wrappedLatex(l)) - \(wrappedLatex(r))"
    case let .Negate(x):
        return "-{\(wrappedLatex(x))}"
    case let .Var(v):
        return v
    case let .Inverse(x):
        return "{\(wrappedLatex(x))}^{-1}"
    case .Power(base: let base, exponent: let exponent):
        return "{\(wrappedLatex(base))}^{\(genLaTex(exponent))}"
    }
}

func wrappedLatex<T>(_ x:Field<T>)-> String {
    switch x {
    case .Number(_):
        return genLaTex(x)
    case .Var(_):
        return genLaTex(x)
    default:
        return "\\left({\(genLaTex(x))}\\right)"
    }
}
