//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/15.
//

import Foundation

func genLaTex(real:Real) -> String {
    switch real {
    case let .Number(num):
        switch num {
        case let .N(n):
            return n.description
        case let .Q(q):
            return "{\(q.numerator.description) \\over \(q.denominator.description)}"
        case let .R(r):
            return r.description
        }
    case let .Add(l,r):
        return "\(wrappedLatex(real: l)) + \(wrappedLatex(real: r))"
    case let .Mul(l, r):
        if case let (.Number(.N(ln)),r) = (l,r) {
            if ln == -1 {
                return "-\(wrappedLatex(real: r))"
            }
        }
        if case let (l,.Number(.N(rn))) = (l,r) {
            if rn == -1 {
                return "-\(wrappedLatex(real: l))"
            }
        }
        return "\(wrappedLatex(real: l)) \\times \(wrappedLatex(real: r))"
        
    case let .Quotient(l, r):
        return "\\frac{\(genLaTex(real: l))}{\(genLaTex(real: r))}"
    case let .Subtract(l, r):
        return "\(wrappedLatex(real: l)) - \(wrappedLatex(real: r))"
    case let .Negate(x):
        return "-{\(wrappedLatex(real: x))}"
    case let .Var(v):
        return v
    case let .Inverse(x):
        return "{\(wrappedLatex(real: x))}^{-1}"
    }
}

func wrappedLatex(real:Real)-> String {
    switch real {
    case .Number(_):
        return genLaTex(real: real)
    case .Var(_):
        return genLaTex(real: real)
    default:
        return "\\left({\(genLaTex(real: real))}\\right)"
    }
}
