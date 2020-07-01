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

func renderMatrix<F:Field & Latexable>(_ m:Mat<F>, kind:String = "pmatrix")-> String {
    let content = m.e.fmap({$0.fmap({($0.latex())})})
    let contentStr = content.all.map { (row) in
        row.all.map({"{ \($0) }"}).joined(separator: " & ")
    }.joined(separator: " \\\\ \n")
    return """
    \\begin{\(kind)}
       \(contentStr)
    \\end{\(kind)}
    """
}


fileprivate func glatex<F:Field & Latexable>(fieldOp:FieldOperators<F>)->String {
    switch fieldOp {
    case let .Mabelian(mab):
        switch mab {
        case let .Inverse(x):
            return (x ^ F._Id).latex()
        case let .Monoid(x): return glatex(mmonoidOp: x)
        case let .Quotient(x, y): return "\\frac{\((x.latex()))}{\((y.latex()))}"
        }
    case let .Abelian(ab):
        return glatex(abelianOp: ab)
    case .Power(base: let base, exponent: let exponent):
        var expTex = (exponent).latex()
        var baseTex = (base).latex()
        if case let .e(.Var(v)) = base.c {
            
        } else {
            baseTex = baseTex.paren
        }
        return "{\(baseTex)}^{\(expTex)}"
    case let .Conjugate(xx):
        return "\\overline{ \((xx).latex()) }"
    case let .Determinant(x):
        if case let .Basis(.Matrix(m)) = x.element {
            return renderMatrix(m, kind: "vmatrix")
        } else {
            return "\\left | \((x.latex())) \\right |"
        }
    }
}
fileprivate func glatex<F:Field & Latexable>(matrixBasis:MatrixBasis<F>)->String {
    switch matrixBasis {
    case let .id(f):
        return "Id_{\((f).latex())}"
    case .zero:
        return "Id_0"
    case let .Matrix(m):
        return renderMatrix(m)
    }
}
fileprivate func glatex<A:Ring & Latexable>(ringOp:RingOperators<A>)-> String {
    switch ringOp {
    case let .MMonoid(o):
        return glatex(mmonoidOp: o)
    case let .Abelian(o):
        return glatex(abelianOp: o)
    }
}
fileprivate func glatex<A:MMonoid & Latexable>(mmonoidOp:MMonoidOperators<A>)-> String {
    switch mmonoidOp {
    case let .Mul(m):
        let flatten = flatMul(m.l) + flatMul(m.r)
        return flatten.reduce(head: { (h) -> String in
            let tex = (h).latex()
            if case .Var(_) = h.element { return tex }
            if case .Basis(_) = (h as? Real)?.element { return tex }
            if case .Power(base: _, exponent: _) = (h as? Real)?.fieldOp { return tex }
            if case .Power(base: _, exponent: _) = (h as? Complex)?.fieldOp { return tex }

            return tex.paren
        }) { (str:String, next) -> String in
            let tex = (next).latex()
            if case .Var(_) = next.element { return str + tex }
            if case .Power(base: _, exponent: _) = (next as? Real)?.fieldOp { return str + tex }
            if case .Power(base: _, exponent: _) = (next as? Complex)?.fieldOp { return str + tex }
            return str + tex.paren
        }
//        return latex(flatten.head) + flatten.tail.map({latex($0).paren}).joined()
    }
}

fileprivate func glatex<A:Abelian & Latexable>(abelianOp:AbelianOperator<A>)-> String {
    switch abelianOp {
    case let .Monoid(m):
        switch m {
        case let .Add(m):
            let flatten = flatAdd(m.l) + flatAdd(m.r)
            return flatten.reduce(head: { (h:A) -> String in
                let tex = (h).latex()
                return tex
            }) { (str:String, nx:A) -> String in
                let tex = (nx).latex()
                if case let .Negate(n) = nx.abelianOp { return str + " - " + (n).latex() }
                return str + " + " + tex
            }
        }
    case let .Negate(x): return "- \((x.latex()).paren)"
    case let .Subtract(x, y):
        return (x + (-y)).latex()
    }
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

func gprettify<A:Prettifiable>(fieldOp:FieldOperators<A>)throws->A {
    switch fieldOp {
    case let .Abelian(a):
        switch a {
        case let .Monoid(x):
            switch x {
            case let .Add(x):
                let flat = flatAdd(x.l) + flatAdd(x.r)
                let pretty = try flat.grouped().fmap { (g) in
                    try (g.all.count, g.head.prettyfy())
                }.fmap { (size, term)->A in
                    if size == 1 {
                        return term
                    } else {
                        let times = A.B.whole(n: size).asNumber(A.self)
                        return try (times * term).prettyfy()
                    }
                }.reduce(+)
                return pretty
            }
        case let .Negate(x): return try .init(abelianOp: .Negate(x.prettyfy()))
        case let .Subtract(x, y): return try .init(abelianOp: .Subtract(x.prettyfy(), y.prettyfy()))
        }
    case let .Conjugate(c): return A(fieldOp: .Conjugate(c))
    case let .Determinant(x): return try A(fieldOp: .Determinant(x.prettyfy()))
    case let .Mabelian(ma):
        switch ma {
        case let .Inverse(x): return try .init(mabelianOp: .Inverse(x.prettyfy()))
        case let .Monoid(x):
            switch x {
            case let .Mul(m):
                let (s,b,_a) = try decomposeMul(m.l * m.r)
                guard let a = _a else {
                    if s {
                        return A(element: .Basis(b))
                    } else {
                        return A(abelianOp: .Negate(A(element: .Basis(b))))
                    }
                }
                let aTerms = flatMul(a)
                
                let groupedTerm = try aTerms.grouped().fmap { (g) in
                    try (g.all.count, g.head.prettyfy())
                }.fmap { (size,term)->A in
                    if size == 1 {
                        return term
                    } else {
                        let exp = A.B.whole(n: size).asNumber(A.self)
                        return A(fieldOp: .Power(base: term, exponent: exp))
                    }
                }.reduce(*)
                
                let ba:A
                if b == .Id {
                    ba = groupedTerm
                } else if b == .Zero {
                    ba = .Zero
                } else {
                    ba = b.asNumber(A.self) * groupedTerm
                }
                
                let nba:A
                if s {
                    nba = ba
                } else {
                    nba = A(abelianOp: .Negate(ba))
                }
                return nba
            }
        case let .Quotient(x, y): return try .init(mabelianOp: .Quotient(x.prettyfy(), y.prettyfy()))
        }
    case .Power(let base, let exponent): return try A(fieldOp: .Power(base: base.prettyfy(), exponent: exponent.prettyfy()))
    }
}
func gprettify<A:Prettifiable>(ringOp:RingOperators<A>)throws->A {
    //todo: come back after implementing power
    switch ringOp {
    case let .Abelian(ab):
        switch ab {
        case let .Monoid(mon):
            switch mon {
            case let .Add(a): return try .init(amonoidOp: .Add(.init(l: a.l.prettyfy(), r: a.r.prettyfy())))
            }
        case let .Negate(x): return try .init(abelianOp: .Negate(x.prettyfy()))
        case let .Subtract(x, y): return try .init(abelianOp: .Subtract(x.prettyfy(), y.prettyfy()))
        }
    case let .MMonoid(mmon):
        switch mmon {
        case let .Mul(x): return try .init(mmonoidOp: .Mul(.init(l: x.l.prettyfy(), r: x.r.prettyfy())))
        }
    }
}
public protocol Prettifiable:Algebra {
    func prettyfy()throws->Self
}
extension Real:Prettifiable {
    public func prettyfy()throws->Self {
        switch c {
        case .e(_): return self
        case let .o(o):
            switch o {
            case let .f(f): return try gprettify(fieldOp: f)
            }
        }
    }
}
extension Complex:Prettifiable {
    public func prettyfy()throws-> Self {
        switch c {
        case let .e(e):
            switch e {
            case let .Basis(b): return try .init(element: .Basis(.init(r: b.r.prettyfy(), i: b.i.prettyfy())))
            case .Var(_): return self
            }
        case let .o(o): return try gprettify(fieldOp: o)
        }
    }
}
extension Matrix:Prettifiable where F:Prettifiable {
    public func prettyfy()throws -> Self {
        switch c {
        case let .e(e):
            switch e {
            case let .Basis(b):
                switch b {
                case let .Matrix(m):
                    return try .init(element: .Basis(.Matrix(.init(e: m.e.fmap({ (row) in
                        try row.fmap({try $0.prettyfy()})
                    })))))
                case let .id(f): return try .init(element: .Basis(.id(f.prettyfy())))
                case .zero: return self
                }
            case .Var(_): return self
            }
        case let .o(o):
            switch o {
            case let .Echelon(m): return try .init(.o(.Echelon(m.prettyfy())))
            case let .Inverse(m): return try .init(.o(.Inverse(m.prettyfy())))
            case let .ReducedEchelon(m): return try .init(.o(.ReducedEchelon(m.prettyfy())))
            case let .Ring(ro): return try gprettify(ringOp: ro)
            case let .Scale(f, m): return try .init(.o(.Scale(f.prettyfy(), m.prettyfy())))
            }
        }
    }
}
public protocol Latexable {
    func latex()->String
}
extension Real:Latexable {
    public func latex() -> String {
        switch c {
        case let .e(e):
            switch e {
            case let .Basis(b):
                switch b {
                case let .N(n):
                    return n.description
                case let .Q(q):
                    return "{\(q.r.numerator.description) \\over \(q.r.denominator.description)}"
                case let .R(r):
                    return r.description
                }
            case let .Var(v):
                return v
            }
        case let .o(o):
            switch o {
            case let .f(fo):
                return glatex(fieldOp: fo)
            }
        }
    }
}
extension Complex:Latexable {
    public func latex() -> String {
        switch c {
        case let .e(e):
            switch e {
            case let .Basis(b):
                var i = (b.i).latex()
                if let e = b.i.element {
                    
                } else {
                    i = i.paren
                }
                if b.i == .Zero {
                    return (b.r).latex()
                } else if b.r == .Zero {
                    return "\(i) {i}"
                } else {
                    return "\((b.r).latex()) + \(i) {i}"
                }
            case let .Var(v):
                return v
            }
        case let .o(o):
            return glatex(fieldOp: o)
        }
    }
}
extension Matrix: Latexable where F:Latexable{
    public func latex() -> String {
        switch c {
        case let .e(e):
            switch e {
            case let .Basis(b):
                return glatex(matrixBasis: b)
            case let .Var(v):
                return v
            }
        case let .o(o):
            switch o {
            case let .Echelon(x): return "E \((x.latex()).paren)"
            case let .Inverse(x): return "{\((x.latex()).paren)}^{-1}"
            case let .ReducedEchelon(x): return "RE \((x.latex()).paren)"
            case let .Ring(x):
                if case let .MMonoid(.Mul(b)) = x {
                    let left:String
                    if case .Add(_) = b.l.amonoidOp {
                        left = b.l.latex().paren
                    } else {
                        left = b.l.latex()
                    }
                    
                    let right:String
                    if case .Add(_) = b.r.amonoidOp {
                        right = b.r.latex().paren
                    } else {
                        right = b.r.latex()
                    }
                    
                    return left + " " + right
                }
                return glatex(ringOp: x)
            case let .Scale(x, y): return "\((x.latex())) \((y.latex()))"
            }
        }
    }
}
func decomposeMul<A:Field>(_ term:A) throws -> (Bool, A.B, A?) {
    if case let .Negate(n) = term.abelianOp {
        let (s,b,a) = try decomposeMul(n)
        return (!s, b, a)
    }
    if case let .Mul(b) = term.mmonoidOp {
        let (ls, lb, la) = try decomposeMul(b.l)
        let (rs, rb, ra) = try decomposeMul(b.r)
        let aa:A?
        if let la = la {
            if let ra = ra { aa = la * ra}
            else {aa = la }
        } else {
            if let ra = ra { aa = ra }
            else { aa = nil }
        }
        
        return try (ls == rs, lb * rb, aa)
    }
    if case let .Basis(b) = term.element {
        if let r = b as? RealBasis  {
            if r.less0 {
                return try (false, -b, nil)
            } else {return (true, b, nil)}
        } else {
            return (true, b, nil)
        }
    } else {
        return (true, A.B.Id, term)
    }
}
