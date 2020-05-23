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
    switch r.element {
    case let .Basis(num):
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
    switch c.element {
    case let .Basis(num):
        return "\(wrappedLatex(num.r)) + \(wrappedLatex(num.i)) i"
    default:
        return nil
    }
    return nil
}
private func unNeg<A:Ring>(_ x:A)-> (Bool, A) {
    if case let .Negate(nx) = x.abelianOp {
        let aaa = unNeg(nx)
        return (!aaa.0, aaa.1)
    } else if case let .Basis(x) = x.element, (x as? RealBasis)?.less0 ?? false {
        return (false, (-x).asNumber(A.self))
    } else {
        return (true, x)
    }
}
private func unNegateMul<A:Field>(_ l:A, _ r:A) -> (Bool, List<A>) {
    let flat = flatMul(l) + flatMul(r)
    let unNegs = flat.fmap(unNeg)
    return unNegs.reduce(head: { (sign, term) in
        (sign, List(term))
    }) { (l,r) in
        (l.0 == r.0 , l.1 + List(r.1) )
    }
}
func genLaTex<F:Field>(_ x:F) -> String {
    if let x = x as? Real, let tex = genLaTex(r: x) {
        return tex
    }
    if let x = x as? Complex, let tex = genLaTex(c: x) {
        return tex
    }
    switch x.element {
    case let .Var(v):
        return v
    default: break
    }
    switch x.fieldOp {
    case let .Ring(.Abelian(.Add(l, r))):
        let flat = flatAdd(x)


        let tex = flat.tail.reduce(genLaTex(flat.head)) { (str, x) -> String in
            switch x.ringOp {
            case let .Abelian( .Negate(v)):
                return str + " - \(wrappedLatex(v))"
            case let .Mul(l,r):
                let (sign, unNeg) = unNegateMul(l, r)
                return str + (sign ? " + " : " - ") + genLaTex(unNeg.reduce(*))
            default:
                return str + " + " + genLaTex(x)
            }
        }
        return tex
    case let .Ring(ring):
        switch ring {
        case let .Abelian(abe):
            switch abe {
            case let .Subtract(l, r):
                return genLaTex(F(abelianOp: .Add(l, -r)))
                
            case let .Negate(x):
                return "- \(wrappedLatex(x))"
            default:
                break
            }

        case let .Mul(l,r):
            let (sign, unNegated) = unNegateMul(l, r)
            let signTex = sign ? "" : "-"
            let headTex:String
            if case .e(_) = unNegated.head.c  {
                headTex = genLaTex(unNegated.head)
            } else {
                switch unNegated.head.fieldOp {
                case .Power(_,_): headTex = genLaTex(unNegated.head)
                default: headTex = genLaTex(unNegated.head).paren
                }
            }
            
            
            let tailTex = unNegated.tail.map { (f) -> String in
                let tex = genLaTex(f)
                if case let .Var(_) = f.element {
                    return tex
                }
                switch f.fieldOp {
                case .Power(_, _): return tex
                default:
                    return "\\left(\(tex)\\right)"
                }
            }.joined(separator: " ")
            return "\(signTex) \(headTex) \(tailTex)"

        default:
            break
        }
    
    case let .Quotient(l, r):
        return "\\frac{\(genLaTex(l))}{\(genLaTex(r))}"

    
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
    switch x.element {
    case let .Basis(n):
        if let n = n as? RealBasis {
            if !n.less0 {
                return tex
            }
        }
    case .Var(_): return tex
    default: break
    }
    switch x.fieldOp {
    case .Power(base: _, exponent: _):        return tex
    default: break
    }
    return tex.paren
}

extension Field {
    func prettify() -> Self {
        switch abelianOp {
        case let .Add(l, r):
            let _flat = flatAdd(self)
            let flat = _flat.grouped().fmap { (g) in
                (g.all.count, g.head)
            }.fmap { (size, term) in
                size == 1 ? term : (B.whole(n: size).asNumber(Self.self) * term).eval()
            }
            return flat.reduce(+)
        default: break
        }
        return self
    }
}
extension Algebra {
    func prettify()->Self {
        if let r = self as? Real {
            return r.prettify() as! Self
        } else if let c = self as? Complex {
            return c.prettify() as! Self
        }
        return self
    }
}
