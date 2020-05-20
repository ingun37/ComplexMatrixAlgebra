//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/15.
//

import Foundation
private extension String {
    var paren: String {
        return "\\left( \(self) \\right)"
    }
}
private func genLaTex(r:Real)-> String? {
    switch r.op.ringOp {
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
private func genLaTex(c:Complex)-> String? {
    switch c.op.ringOp {
    case let .Number(num):
        return "\(wrappedLatex(num.r)) + \(wrappedLatex(num.i)) i"
    default:
        return nil
    }
    return nil
}
private func unNegateMul<A:Field>(_ l:A, _ r:A) -> (Bool, List<A>) {
    let flat = flatMul(l) + flatMul(r)
    let minus1 = A._Id
    let abs = flat.all.filter { $0 != minus1 }
    let negates = flat.all.count - abs.count
    let unNegated = abs.decompose() ?? List(A.Id, [])
    return (negates%2 == 0, unNegated)
}
func genLaTex<F:Field>(_ x:F) -> String {
    if let x = x as? Real, let tex = genLaTex(r: x) {
        return tex
    }
    if let x = x as? Complex, let tex = genLaTex(c: x) {
        return tex
    }
    switch x.op.fieldOp {
    case let .Ring(ring):
        switch ring {
        case let .Subtract(l, r):
            return genLaTex(F.O.RingO.Add(l, F._Id * r).sum.asField)

        case let .Add(l,r):
            let flat = flatAdd(x)
            let tex = flat.tail.reduce(genLaTex(flat.head)) { (str, x) -> String in
                switch x.op.ringOp {
                case let .Negate(v):
                    return str + " - \\left( \(genLaTex(v)) \\right)"
                case let .Mul(l,r):
                    let (sign, unNeg) = unNegateMul(l, r)
                    return str + (sign ? " + " : " - ") + genLaTex(unNeg.reduce(*))
                default:
                    return str + " + " + genLaTex(x)
                }
            }
            return tex
        case let .Mul(l,r):
            let (sign, unNegated) = unNegateMul(l, r)
            let signTex = sign ? "" : "-"
            let headTex:String
            
            switch unNegated.head.op.fieldOp {
            case .Var(_): headTex = genLaTex(unNegated.head)
            case .Power(_,_): headTex = genLaTex(unNegated.head)
            default:
                headTex = genLaTex(unNegated.head).paren
            }
            
            let tailTex = unNegated.tail.map { (f) -> String in
                let tex = genLaTex(f)
                switch f.op.fieldOp {
                case .Var(_): return tex
                case .Power(_, _): return tex
                default:
                    return "\\left(\(tex)\\right)"
                }
            }.joined(separator: " ")
            return "\(signTex) \(headTex) \(tailTex)"
        case let .Negate(x):
            return genLaTex(F._Id * x)
        default:
            break
        }
    
    case let .Quotient(l, r):
        return "\\frac{\(genLaTex(l))}{\(genLaTex(r))}"

    case let .Var(v):
        return v
    case let .Inverse(x):
        return "{\(wrappedLatex(x))}^{-1}"
    case .Power(base: let base, exponent: let exponent):
        let expTex = genLaTex(exponent)
        let baseTex = wrappedLatex(base)
        return "{\(baseTex)}^{\(expTex)}"
    case let .Conjugate(xx):
        return "\\overline{ \(genLaTex(xx)) }"
    default:
        return "error"
    }
    return "error"
}

private func wrappedLatex<A:Field>(_ x:A)-> String {
    let tex = genLaTex(x)
    switch x.op.fieldOp {
    case let .Ring(ring):
        switch ring {
        case let .Number(n):
            if n is RealBasis {
                return tex
            }
        default: break
        }
    
    case .Var(_):        return tex
    case .Power(base: _, exponent: _):        return tex
    default: break
    }
    return tex.paren
}
