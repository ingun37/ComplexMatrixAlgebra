//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/15.
//

import Foundation
extension String {
    var paren: String {
        return "\\left( \(self) \\right)"
    }
}
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
func unNegateMul<T>(_ lr:FMul<T>) -> (Bool, List<Field<T>>) {
    let flat = lr.flat()
    let minus1 = Field<T>._id
    let abs = flat.all.filter { $0 != minus1 }
    let negates = flat.all.count - abs.count
    let unNegated = abs.decompose() ?? List(Field<T>.id, [])
    return (negates%2 == 0, unNegated)
}
func genLaTex<T>(_ x:Field<T>) -> String {
    typealias F = Field<T>
    if let x = x as? Real, let tex = genLaTex(r: x) {
        return tex
    }
    if let x = x as? Complex, let tex = genLaTex(c: x) {
        return tex
    }
    switch x {
    case let .Add(lr):
        let flat = lr.flat()
        let tex = flat.tail.reduce(genLaTex(flat.head)) { (str, x) -> String in
            switch x {
            case let .Negate(v):
                return str + " - \\left( \(genLaTex(v)) \\right)"
            case let .Mul(v):
                let (sign, unNeg) = unNegateMul(v)
                return str + (sign ? " + " : " - ") + genLaTex(unNeg.reduce(*))
            default:
                return str + " + " + genLaTex(x)
            }
        }
        return tex
    case let .Mul(lr):
        let (sign, unNegated) = unNegateMul(lr)
        let signTex = sign ? "" : "-"
        let headTex:String
        
        switch unNegated.head {
        case .Var(_): headTex = genLaTex(unNegated.head)
        case .Power(_,_): headTex = genLaTex(unNegated.head)
        default:
            headTex = genLaTex(unNegated.head).paren
        }
        
        let tailTex = unNegated.tail.map { (f) -> String in
            let tex = genLaTex(f)
            switch f {
            case .Var(_): return tex
            case .Power(_, _): return tex
            default:
                return "\\left(\(tex)\\right)"
            }
        }.joined(separator: " ")
        return "\(signTex) \(headTex) \(tailTex)"
    case let .Quotient(l, r):
        return "\\frac{\(genLaTex(l))}{\(genLaTex(r))}"
    case let .Subtract(l, r):
        return genLaTex(.Add(FAdd<T>(l, F._id * r)))
    case let .Negate(x):
        return genLaTex(F._id * x)
    case let .Var(v):
        return v
    case let .Inverse(x):
        return "{\(wrappedLatex(x))}^{-1}"
    case .Power(base: let base, exponent: let exponent):
        let expTex = genLaTex(exponent)
        let baseTex = wrappedLatex(base)
        return "{\(baseTex)}^{\(expTex)}"
    default:
        return "error"
    }
}

func wrappedLatex<T>(_ x:Field<T>)-> String {
    let tex = genLaTex(x)
    switch x {
    case let .Number(n):
        if n is RealNumber {
            return tex
        }
    case .Var(_):        return tex
    case .Power(base: _, exponent: _):        return tex
    default: break
    }
    return tex.paren
}
