//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/15.
//

import Foundation
func genLaTex(r:Real)-> String? {
    switch r {
    case let .Number(num):
        switch num {
        case let .N(n):
            return n.description
        case let .Q(q):
            return "{\(q.numerator.description) \\over \(q.denominator.description)}"
        case let .R(r):
            return r.description
        }
    case let .Mul(lr):
        if case let (.Number(.N(ln)),r) = (lr.l,lr.r) {
            if ln == -1 {
                return "-\(wrappedLatex(r))"
            }
        }
        if case let (l,.Number(.N(rn))) = (lr.l,lr.r) {
            if rn == -1 {
                return "-\(wrappedLatex(l))"
            }
        }
    default:
        return nil
    }
    return nil
}
func genLaTex(c:Complex)-> String? {
    switch c {
    case let .Number(num):
        return "\(wrappedLatex(num.r)) + \(wrappedLatex(num.i)) i"
    default:
        return nil
    }
    return nil
}
func genLaTex<T>(_ x:Field<T>) -> String {
    if let x = x as? Real, let tex = genLaTex(r: x) {
        return tex
    }
    if let x = x as? Complex, let tex = genLaTex(c: x) {
        return tex
    }
    switch x {
    case let .Add(lr):
        return "\(wrappedLatex(lr.l)) + \(wrappedLatex(lr.r))"
    case let .Mul(lr):
        let flat = lr.flat()
        let minus1 = (-Field<T>.id).eval()
        let abs = flat.all.filter { $0 != minus1 }
        let negates = flat.all.count - abs.count
        if negates > 0 {
            let unNegated = (abs.decompose() ?? List(Field<T>.id, [])).reduce(*)
            let tex = wrappedLatex(unNegated)
            return (negates%2 == 0 ? "" : "-") + tex
        }
        return "\(wrappedLatex(lr.l)) \(wrappedLatex(lr.r))"
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
    default:
        return "error"
    }
}

func wrappedLatex<T>(_ x:Field<T>)-> String {
    switch x {
    case .Number(_):
        return genLaTex(x)
    case .Var(_):
        return genLaTex(x)
    default:
        let tex = genLaTex(x)
        if !tex.contains(" \\times ") && !tex.contains("+") && !tex.contains("-") {
            return tex
        } else {
            return "\\left({\(tex)}\\right)"
        }
    }
}
