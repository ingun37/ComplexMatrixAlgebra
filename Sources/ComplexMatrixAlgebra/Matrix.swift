//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/14.
//

import Foundation


struct MatrixBinary: AlgebraBinaryOperator {
    let l: Matrix
    let r: Matrix
}

struct Elements: Equatable{
    let e:[[Complex]]
}

indirect enum Matrix: Algebra {
    case Scale(Complex, Matrix)
    case Mul(MatrixBinary)
    case Add(MatrixBinary)
    case a(Elements)
    
    func eval() -> Matrix {
        switch self {
        case let .Scale(k, m):
            let k = k.eval()
            let m = m.eval()
            if case let Matrix.a(m) = m {
                let newElems = m.e.map { (row) in
                    row.map { (f) in
                        Complex.Mul(ComplexBinary(l: k, r: f)).eval()
                    }
                }
                return Matrix.a(Elements(e: newElems))
            }
            return .Scale(k, m)
        case let .Mul(lr):
            let l = lr.l.eval()
            let r = lr.r.eval()
            if case let .a(l) = l {
                if case let .a(r) = r {
                    if l.colLen == r.rowLen && l.rowLen == r.colLen {
                        let newElems = l.rows.map { (lrow) in
                            r.cols.map { (rcol) in
                                zip(lrow, rcol).map { (x,y) in Complex.Mul(ComplexBinary(l: x, r: y)) }.reduce(Complex.zero) { (x, fx) in Complex.Add(ComplexBinary(l: x, r: fx)) }.eval()
                            }
                        }
                        return .a(Elements(e: newElems))
                    }
                }
            }
            return .Mul(MatrixBinary(l: l, r: r))
        case let .Add(lr):
            let terms = lr.associativeFlat()
            return Matrix.evalTerms(head: terms.first!, tail: terms.dropFirst())
        case let .a(m):
            let newElems = m.e.map { (row) in
                row.map { (f) in
                    f.eval()
                }
            }
            return .a(Elements(e: newElems))
        }
    }
    
    static func evalTerms<T:Collection>(head:Matrix, tail:T) -> Matrix where T.Element == Matrix{
        let terms = [head] + tail
        for i in 0..<terms.count {
            for j in (0..<terms.count).without(i) {
                let l = terms[i]
                let r = terms[j]
                if case let .a(l) = l, case let .a(r) = r {
                    if l.dim == r.dim {
                        let newElems = zip(l.e, r.e).map { (rowL, rowR) in
                            zip(rowL, rowR).map { (x,y) in
                                Complex.Add(ComplexBinary(l: x, r: y)).eval()
                            }
                        }
                        let resultMat = Matrix.a(Elements(e: newElems))
                        let newTerms = (0..<terms.count).without(i, j).map({terms[$0]})
                        return evalTerms(head: resultMat, tail: newTerms)
                    }
                }
            }
        }
        return tail.reduce(head) { (x, fx) in
            Matrix.Add(MatrixBinary(l: x, r: fx))
        }
    }
    func iso(_ to: Matrix) -> Bool {
        switch self {
        case let .Scale(k, m):
            guard case let .Scale(_k, _m) = to else { return false }
            return k.iso(_k) && m.iso(_m)
        case let .Mul(x):
            guard case let .Mul(y) = to else { return false }
            return x.l.iso(y.l) && x.r.iso(y.r)
        case let .Add(x):
            guard case let .Add(y) = to else { return false }
            return x.commutativeIso(y)
        case let .a(x):
            guard case let .a(y) = to else { return false }
            guard x.dim == y.dim else { return false }
            return zip(y.e, x.e).allSatisfy { (rowX, rowY) -> Bool in
                zip(rowX, rowY).allSatisfy { (_x,_y) -> Bool in
                    _x.iso(_y)
                }
            }
        }
    }
    
    static func == (lhs: Matrix, rhs: Matrix) -> Bool {
        switch lhs {
        case let .Scale(k, m):
            guard case let .Scale(_k, _m) = rhs else { return false }
            return k == (_k) && m == (_m)
        case let .Mul(x):
            guard case let .Mul(y) = rhs else { return false }
            return x.l == (y.l) && x.r == (y.r)
        case let .Add(x):
            guard case let .Add(y) = rhs else { return false }
            return x.l == (y.l) && x.r == (y.r)
        case let .a(x):
            guard case let .a(y) = rhs else { return false }
            guard x.dim == y.dim else { return false }
            return zip(y.e, x.e).allSatisfy { (rowX, rowY) -> Bool in
                zip(rowX, rowY).allSatisfy { (_x,_y) -> Bool in
                    _x == (_y)
                }
            }
        }
    }
}
