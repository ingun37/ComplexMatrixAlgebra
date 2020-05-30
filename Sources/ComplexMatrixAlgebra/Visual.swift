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
    let flat = flatRingMul(l) + flatRingMul(r)
    let unNegs = flat.fmap(unNeg)
    return unNegs.reduce(head: { (sign, term) in
        (sign, List(term))
    }) { (l,r) in
        (l.0 == r.0 , l.1 + List(r.1) )
    }
}
func renderMatrix<F:Field>(_ m:Mat<F>, kind:String = "pmatrix")-> String {
    let content = m.e.fmap({$0.fmap({genLaTex($0)})})
    let contentStr = content.all.map { (row) in
        row.all.map({"{ \($0) }"}).joined(separator: " & ")
    }.joined(separator: " \\\\ \n")
    return """
    \\begin{\(kind)}
       \(contentStr)
    \\end{\(kind)}
    """
}
func genLaTex<F:Field>(_ m:Matrix<F>) -> String {
    switch m.c {
    case let .e(me):
        switch me {
        case let .Basis(b):
            switch b {
            case let .id(f):
                return "Id_{\(genLaTex(f))}"
            case .zero:
                return "Id_0"
            case let .Matrix(m):
                return renderMatrix(m)
            }

        case let .Var(v):
            return v
        }
    case let .o(o):
        switch o {
        case let .Inverse(m):
            let mTex = genLaTex(m)
            return "{\(mTex)}^{-1}"
        default: break
        }
    default: break
    }
    return "error"
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
    switch x.ringOp {
    case let .Abelian(abe):
        switch abe {
        case let .Subtract(l, r):
            return genLaTex(F(amonoidOp: .Add(.init(l:l, r:-r))))
            
        case let .Negate(x):
            return "- \(wrappedLatex(x))"
        default:
            break
        }

    case let .MMonoid( .Mul(b)):
        let (sign, unNegated) = unNegateMul(b.l, b.r)
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

    default: break
    }
    
    switch x.fieldOp {
    case let (.Abelian(.Monoid(.Add(b)))):
        let flat = flatAbelianAdd(x)
        let tex = flat.tail.reduce(genLaTex(flat.head)) { (str, x) -> String in
            switch x.ringOp {
            case let .Abelian( .Negate(v)):
                let (sign, xx) = unNeg(v)
                if sign {
                    return str + " - \(genLaTex(xx))"
                } else {
                    return str + " + \(genLaTex(xx))"
                }
            case let .MMonoid( .Mul(b)):
                let (sign, unNeg) = unNegateMul(b.l, b.r)
                return str + (sign ? " + " : " - ") + genLaTex(unNeg.reduce(*))
            default:
                return str + " + " + genLaTex(x)
            }
        }
        return tex
    case let .Mabelian( .Quotient(l, r)):
        return "\\frac{\(genLaTex(l))}{\(genLaTex(r))}"

    
    case let .Mabelian( .Inverse(x)):
        return "{\(wrappedLatex(x))}^{-1}"
    case .Power(base: let base, exponent: let exponent):
        let expTex = genLaTex(exponent)
        let baseTex = wrappedLatex(base)
        return "{\(baseTex)}^{\(expTex)}"
    case let .Conjugate(xx):
        return "\\overline{ \(genLaTex(xx)) }"
    case let .Determinant(mat):
        switch mat.element {
        case let .Basis(.Matrix(m)):
            return renderMatrix(m, kind: "vmatrix")
        default: break
        }
        
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
        if let com = self as? Complex {
            if case let .e(.Basis(com)) = com.c {
                return ComplexBasis(r: com.r.prettify(), i: com.i.prettify()).f as! Self
            }
        }
        switch ringOp {
        case let .MMonoid( .Mul(b)):
            let (sign, _flat) = unNegateMul(b.l, b.r)
            let (numbers, terms) = _flat.all.seperate({
                if case .e(.Basis(_)) = $0.c { return true }
                else {return false}
            })
            let prettyTerms = terms.decompose()?.grouped().fmap { (g) in
                (g.all.count, g.head.prettify())
            }.fmap { (size,term) in
                size == 1 ? term : Self.init(fieldOp: .Power(base: term, exponent: B.whole(n: size).asNumber(Self.self)))
            }.reduce(*)
            
            let prettyNumbers = numbers.decompose()?.reduce(*).eval()
            
            let aa:Self?
            
            if let pn = prettyNumbers, let pt = prettyTerms {
                aa = pn * pt
            } else if let pn = prettyNumbers {
                aa = pn
            } else if let pt = prettyTerms {
                aa = pt
            } else {
                aa = nil
            }
            
            if let aa = aa {
                return sign ? aa : Self.init(abelianOp: .Negate(aa))
            }
        default: break
        }
        switch amonoidOp {
        case let .Add(b):
            let _flat = flatAbelianAdd(self)
            let flat = _flat.grouped().fmap { (g) in
                (g.all.count, g.head.prettify())
            }.fmap { (size, term) in
                size == 1 ? term : (B.whole(n: size).asNumber(Self.self) * term).prettify()
            }
            return flat.reduce(+)
        default: break
        }
        return self
    }
}

func latex<F:Field>(fieldOp:FieldOperators<F>)->String {
    switch fieldOp {
    case let .Mabelian(mab):
        return latex(mabelianOp: mab)
    case let .Abelian(ab):
        return latex(abelianOp: ab)
    case .Power(base: let base, exponent: let exponent):
        let expTex = latex(exponent)
        let baseTex = latex(base)
        return "{\(baseTex)}^{\(expTex)}"
    case let .Conjugate(xx):
        return "\\overline{ \(latex(xx)) }"
    case let .Determinant(x):
        if case let .Basis(.Matrix(m)) = x.element {
            return renderMatrix(m, kind: "vmatrix")
        } else {
            return "\\left | \(latex(x)) \\right |"
        }
    }
}
func latex<F:Field>(matrixBasis:MatrixBasis<F>)->String {
    switch matrixBasis {
    case let .id(f):
        return "Id_{\(genLaTex(f))}"
    case .zero:
        return "Id_0"
    case let .Matrix(m):
        return renderMatrix(m)
    }
}
func latex<A:Ring>(ringOp:RingOperators<A>)-> String {
    switch ringOp {
    case let .MMonoid(o):
        return latex(mmonoidOp: o)
    case let .Abelian(o):
        return latex(abelianOp: o)
    }
}
func latex<A:MMonoid>(mmonoidOp:MMonoidOperators<A>)-> String {
    switch mmonoidOp {
    case let .Mul(m):
        let flatten = flatMul(m.l) + flatMul(m.r)
        return latex(flatten.head) + flatten.tail.map({latex($0).paren}).joined()
    }
}
func latex<A:AMonoid>(amonoidOp:AMonoidOperators<A>)-> String {
    switch amonoidOp {
    case let .Add(m):
        let flatten = flatAdd(m.l) + flatAdd(m.r)
        return flatten.all.map({latex($0)}).joined(separator: " + ")
    }
}
func latex<A:MAbelian>(mabelianOp:MAbelianOperator<A>)-> String {
    switch mabelianOp {
    case let .Inverse(x): return "{\(latex(x))}^{-1}"
    case let .Monoid(x): return latex(mmonoidOp: x)
    case let .Quotient(x, y): return "\\frac{\(latex(x))}{\(latex(y))}"
    }
}
func latex<A:Abelian>(abelianOp:AbelianOperator<A>)-> String {
    switch abelianOp {
    case let .Monoid(m): return latex(amonoidOp: m)
    case let .Negate(x): return "- \(latex(x).paren)"
    case let .Subtract(x, y): return "\(latex(x).paren) - \(latex(y).paren)"
    }
}
func latex<F:Field>(matrixOp:MatrixOp<F>)->String {
    switch matrixOp {
    case let .Echelon(x): return "E \(latex(x).paren)"
    case let .Inverse(x): return "{\(latex(x).paren)}^{-1}"
    case let .ReducedEchelon(x): return "RE \(latex(x).paren)"
    case let .Ring(x): return latex(ringOp: x)
    case let .Scale(x, y): return "\(latex(x)) \(latex(y))"
    }
}
func latex<A:Algebra>(_ a:A)->String {
    if let a = a as? Real {
        switch a.c {
        case let .e(e):
            switch e {
            case let .Basis(b):
                switch b {
                case let .N(n):
                    return n.description
                case let .Q(q):
                    return "{\(q.numerator.description) \\over \(q.denominator.description)}"
                case let .R(r):
                    return r.description
                }
            case let .Var(v):
                return v
            }
        case let .o(o):
            switch o {
            case let .f(fo):
                return latex(fieldOp: fo)
            }
        }
    } else if let a = a as? Complex {
        switch a.c {
        case let .e(e):
            switch e {
            case let .Basis(b):
                return "\(latex(b.r)) + \(latex(b.i)) {i}"
            case let .Var(v):
                return v
            }
        case let .o(o):
            return latex(fieldOp: o)
        }
    } else if let a = a as? Matrix<Real> {
        switch a.c {
        case let .e(e):
            switch e {
            case let .Basis(b):
                return latex(matrixBasis: b)
            case let .Var(v):
                return v
            }
        case let .o(o):
            return latex(matrixOp: o)
        }
    } else if let a = a as? Matrix<Complex> {
        switch a.c {
        case let .e(e):
            switch e {
            case let .Basis(b):
                return latex(matrixBasis: b)
            case let .Var(v):
                return v
            }
        case let .o(o):
            return latex(matrixOp: o)
        }
    }
    return "unknown algebra"
}
func flatMul<A:MMonoid>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Mul(b) = x.mmonoidOp {
            return [b.l,b.r]
        } else {
            return []
        }
    }
}
func flatAdd<A:AMonoid>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Add(bin) = x.amonoidOp {
            return [bin.l,bin.r]
        } else {
            return []
        }
    }
}
