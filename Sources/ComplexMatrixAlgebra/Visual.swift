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

func renderMatrix<F:Field>(_ m:Mat<F>, kind:String = "pmatrix")-> String {
    let content = m.e.fmap({$0.fmap({latex($0)})})
    let contentStr = content.all.map { (row) in
        row.all.map({"{ \($0) }"}).joined(separator: " & ")
    }.joined(separator: " \\\\ \n")
    return """
    \\begin{\(kind)}
       \(contentStr)
    \\end{\(kind)}
    """
}


func latex<F:Field>(fieldOp:FieldOperators<F>)->String {
    switch fieldOp {
    case let .Mabelian(mab):
        switch mab {
        case let .Inverse(x):
            return latex(x ^ F._Id)
        case let .Monoid(x): return latex(mmonoidOp: x)
        case let .Quotient(x, y): return "\\frac{\(latex(x))}{\(latex(y))}"
        }
    case let .Abelian(ab):
        return latex(abelianOp: ab)
    case .Power(base: let base, exponent: let exponent):
        var expTex = latex(exponent)
        var baseTex = latex(base)
        if case let .e(.Var(v)) = base.c {
            
        } else {
            baseTex = baseTex.paren
        }
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
        return "Id_{\(latex(f))}"
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
        return flatten.reduce(head: { (h) -> String in
            let tex = latex(h)
            if case .Var(_) = h.element { return tex }
            if case .Basis(_) = (h as? Real)?.element { return tex }
            if case .Power(base: _, exponent: _) = (h as? Real)?.fieldOp { return tex }
            if case .Power(base: _, exponent: _) = (h as? Complex)?.fieldOp { return tex }

            return tex.paren
        }) { (str:String, next) -> String in
            let tex = latex(next)
            if case .Var(_) = next.element { return str + tex }
            if case .Power(base: _, exponent: _) = (next as? Real)?.fieldOp { return str + tex }
            if case .Power(base: _, exponent: _) = (next as? Complex)?.fieldOp { return str + tex }
            return str + tex.paren
        }
//        return latex(flatten.head) + flatten.tail.map({latex($0).paren}).joined()
    }
}

func latex<A:Abelian>(abelianOp:AbelianOperator<A>)-> String {
    switch abelianOp {
    case let .Monoid(m):
        switch m {
        case let .Add(m):
            let flatten = flatAdd(m.l) + flatAdd(m.r)
            return flatten.reduce(head: { (h:A) -> String in
                let tex = latex(h)
                return tex
            }) { (str:String, nx:A) -> String in
                let tex = latex(nx)
                if case let .Negate(n) = nx.abelianOp { return str + " - " + latex(n) }
                return str + " + " + tex
            }
        }
    case let .Negate(x): return "- \(latex(x).paren)"
    case let .Subtract(x, y):
        return latex(x + (-y))
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
public func latex<A:Algebra>(_ a:A)->String {
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
                var i = latex(b.i)
                if let e = b.i.element {
                    
                } else {
                    i = i.paren
                }
                if b.i == .Zero {
                    return latex(b.r)
                } else if b.r == .Zero {
                    return "\(i) {i}"
                } else {
                    return "\(latex(b.r)) + \(i) {i}"
                }
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

func gprettify<A:Prettifiable>(fieldOp:FieldOperators<A>)->A {
    switch fieldOp {
    case let .Abelian(a):
        switch a {
        case let .Monoid(x):
            switch x {
            case let .Add(x):
                let flat = flatAdd(x.l) + flatAdd(x.r)
                let pretty = flat.grouped().fmap { (g) in
                    (g.all.count, g.head.prettyfy())
                }.fmap { (size, term)->A in
                    if size == 1 {
                        return term
                    } else {
                        let times = A.B.whole(n: size).asNumber(A.self)
                        return (times * term).prettyfy()
                    }
                }.reduce(+)
                return pretty
            }
        case let .Negate(x): return .init(abelianOp: .Negate(x.prettyfy()))
        case let .Subtract(x, y): return .init(abelianOp: .Subtract(x.prettyfy(), y.prettyfy()))
        }
    case let .Conjugate(c): return A(fieldOp: .Conjugate(c))
    case let .Determinant(x): return A(fieldOp: .Determinant(x.prettyfy()))
    case let .Mabelian(ma):
        switch ma {
        case let .Inverse(x): return .init(mabelianOp: .Inverse(x.prettyfy()))
        case let .Monoid(x):
            switch x {
            case let .Mul(m):
                let flat = flatMul(m.l) + flatMul(m.r)
                let prettyTerms = flat.grouped().fmap { (g) in
                    (g.all.count, g.head.prettyfy())
                }.fmap { (size,term)->A in
                    if size == 1 {
                        return term
                    } else {
                        let exp = A.B.whole(n: size).asNumber(A.self)
                        return A(fieldOp: .Power(base: term, exponent: exp))
                    }
                }.reduce(*)
                return prettyTerms
            }
        case let .Quotient(x, y): return .init(mabelianOp: .Quotient(x.prettyfy(), y.prettyfy()))
        }
    case .Power(let base, let exponent): return A(fieldOp: .Power(base: base.prettyfy(), exponent: exponent.prettyfy()))
    }
}
func gprettify<A:Prettifiable>(ringOp:RingOperators<A>)->A {
    //todo: come back after implementing power
    switch ringOp {
    case let .Abelian(ab):
        switch ab {
        case let .Monoid(mon):
            switch mon {
            case let .Add(a): return .init(amonoidOp: .Add(.init(l: a.l.prettyfy(), r: a.r.prettyfy())))
            }
        case let .Negate(x): return .init(abelianOp: .Negate(x.prettyfy()))
        case let .Subtract(x, y): return .init(abelianOp: .Subtract(x.prettyfy(), y.prettyfy()))
        }
    case let .MMonoid(mmon):
        switch mmon {
        case let .Mul(x): return .init(mmonoidOp: .Mul(.init(l: x.l.prettyfy(), r: x.r.prettyfy())))
        }
    }
}
protocol Prettifiable:Algebra {
    func prettyfy()->Self
}
extension Real:Prettifiable {
    func prettyfy()->Self {
        switch c {
        case .e(_): return self
        case let .o(o):
            switch o {
            case let .f(f): return gprettify(fieldOp: f)
            }
        }
    }
}
extension Complex:Prettifiable {
    func prettyfy()-> Self {
        switch c {
        case let .e(e):
            switch e {
            case let .Basis(b): return .init(element: .Basis(.init(r: b.r.prettyfy(), i: b.i.prettyfy())))
            case .Var(_): return self
            }
        case let .o(o): return gprettify(fieldOp: o)
        }
    }
}
extension Matrix:Prettifiable where F:Prettifiable {
    func prettyfy()-> Self {
        switch c {
        case let .e(e):
            switch e {
            case let .Basis(b):
                switch b {
                case let .Matrix(m):
                    return .init(element: .Basis(.Matrix(.init(e: m.e.fmap({ (row) in
                        row.fmap({$0.prettyfy()})
                    })))))
                case let .id(f): return .init(element: .Basis(.id(f.prettyfy())))
                case .zero: return self
                }
            case .Var(_): return self
            }
        case let .o(o):
            switch o {
            case let .Echelon(m): return .init(.o(.Echelon(m.prettyfy())))
            case let .Inverse(m): return .init(.o(.Inverse(m.prettyfy())))
            case let .ReducedEchelon(m): return .init(.o(.ReducedEchelon(m.prettyfy())))
            case let .Ring(ro): return gprettify(ringOp: ro)
            case let .Scale(f, m): return .init(.o(.Scale(f.prettyfy(), m.prettyfy())))
            }
        }
    }
}
