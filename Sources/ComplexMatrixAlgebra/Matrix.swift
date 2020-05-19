//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/14.
//

import Foundation

struct Dimension:Hashable {
    let rows:Int
    let cols:Int
    init(_ rows:Int, _ cols:Int) {
        self.rows = rows
        self.cols = cols
    }
}

struct MatrixNumber<F:Field>:Underlying {
    let e:List<List<F>>
    
    static func * (l:MatrixNumber, r:MatrixNumber)->MatrixNumber? {
        guard l.colLen == r.rowLen else { return nil }
        let newElems = l.rows.fmap { (lrow) in
            r.cols.fmap { (rcol) in
                lrow.fzip(rcol).fmap(*).reduce(+).eval()
            }
        }
        return MatrixNumber(e: newElems)
    }
    
    static func + (l:MatrixNumber, r:MatrixNumber)->MatrixNumber? {
        guard l.dim == r.dim else { return nil }
        let newElements = l.rows.fzip(r.rows).fmap { (l,r) in
            l.fzip(r).fmap(+).fmap({$0.eval()})
        }
        return MatrixNumber(e: newElements)
    }
    
    var rowLen:Int {
        return e.all.count
    }
    var colLen:Int {
        return e.all.map({$0.all.count}).max() ?? e.head.all.count
    }
    var dim:(Int, Int) {
        return (rowLen, colLen)
    }
    var dimen:Dimension {
        return Dimension(rowLen, colLen)
    }
    func row(_ i:Int) -> List<F> {
        return e.all[i]
    }
    func col(_ i:Int) -> List<F> {
        return e.reduce(head: {List($0.all[i])}) { (l, r) in
            l + List(r.all[i])
        }
    }
    var rows:List<List<F>> {
        return e
    }
    var cols:List<List<F>> {
        return List(0, (1..<colLen)).fmap({self.col($0)})
    }
    var asOperator:MatrixOperators<F> {
        return .Number(self)
    }
}
indirect enum MatrixOperators<F:Field>:OperatorSum {
    typealias A = Matrix<F>
    typealias Num = MatrixNumber<F>
    
    case Add(A,A)
    case Number(Num)
    case Mul(A,A)
    
    var asMatrix:Matrix<F> {
        return Matrix(op: self)
    }
}

struct Matrix<F:Field>:Algebra {
    func eval() -> Matrix {
        switch op {
        case .Number(_):
            return self
        case let .Add(_l, _r):
            let l = _l.eval()
            let r = _r.eval()
            switch (l.op,r.op) {
            case let (.Number(ln), .Number(rn)):
                return (ln + rn)?.asOperator.asMatrix ?? OpSum.Add(l,r).asMatrix
            default:
                return OpSum.Add(l,r).asMatrix
            }
        case let .Mul(_l, _r):
            let l = _l
            let r = _r
            switch (l.op, r.op) {
            case let (.Number(ln), .Number(rn)):
                return (ln * rn)?.asOperator.asMatrix ?? OpSum.Mul(l, r).asMatrix
            default:
                return OpSum.Mul(l,r).asMatrix
            }
        }
    }
    
    func same(_ to: Matrix) -> Bool {
        switch (op, to.op) {
        case (.Add(_, _),.Add(_,_)):
            return commuteSame(flatMatrixAdd(self).all, flatMatrixAdd(to).all)
        default:
            return self == to
        }
    }
    let op: OpSum
    
    typealias OpSum = MatrixOperators<F>
    
    
}


//indirect enum Matrix: Algebra {
//    case Scale(Complex, Matrix)
//    case Mul(MatrixBinary)
//    case Add(MatrixBinary)
//    case a(Elements)
//
//    func eval() -> Matrix {
//        switch self {
//        case let .Scale(k, m):
//            let k = k.eval()
//            let m = m.eval()
//            if case let Matrix.a(m) = m {
//                let newElems = m.e.map { (row) in
//                    row.map { (f) in
//                        Complex.Mul(ComplexBinary(l: k, r: f)).eval()
//                    }
//                }
//                return Matrix.a(Elements(e: newElems))
//            }
//            return .Scale(k, m)
//        case let .Add(lr):
//            let terms = lr.associativeFlat()
//            return Matrix.addTerms(head: terms.first!, tail: terms.dropFirst())
//        case let .a(m):
//            let newElems = m.e.map { (row) in
//                row.map { (f) in
//                    f.eval()
//                }
//            }
//            return .a(Elements(e: newElems))
//        }
//    }
//
//    static func addTerms<T:Collection>(head:Matrix, tail:T) -> Matrix where T.Element == Matrix{
//        let terms = [head] + tail
//        for i in 0..<terms.count {
//            for j in (0..<terms.count).without(i) {
//                let l = terms[i]
//                let r = terms[j]
//                if case let .a(l) = l, case let .a(r) = r {
//                    if l.dim == r.dim {
//                        let newElems = zip(l.e, r.e).map { (rowL, rowR) in
//                            zip(rowL, rowR).map { (x,y) in
//                                Complex.Add(ComplexBinary(l: x, r: y)).eval()
//                            }
//                        }
//                        let resultMat = Matrix.a(Elements(e: newElems))
//                        let newTerms = (0..<terms.count).without(i, j).map({terms[$0]})
//                        return addTerms(head: resultMat, tail: newTerms)
//                    }
//                }
//            }
//        }
//        return tail.reduce(head) { (x, fx) in
//            Matrix.Add(MatrixBinary(l: x, r: fx))
//        }
//    }
//    func iso(_ to: Matrix) -> Bool {
//        switch self {
//        case let .Scale(k, m):
//            guard case let .Scale(_k, _m) = to else { return false }
//            return k.iso(_k) && m.iso(_m)
//        case let .Mul(x):
//            guard case let .Mul(y) = to else { return false }
//            return x.l.iso(y.l) && x.r.iso(y.r)
//        case let .Add(x):
//            guard case let .Add(y) = to else { return false }
//            return x.commutativeIso(y)
//        case let .a(x):
//            guard case let .a(y) = to else { return false }
//            guard x.dim == y.dim else { return false }
//            return zip(y.e, x.e).allSatisfy { (rowX, rowY) -> Bool in
//                zip(rowX, rowY).allSatisfy { (_x,_y) -> Bool in
//                    _x.iso(_y)
//                }
//            }
//        }
//    }
//
//    static func == (lhs: Matrix, rhs: Matrix) -> Bool {
//        switch lhs {
//        case let .Scale(k, m):
//            guard case let .Scale(_k, _m) = rhs else { return false }
//            return k == (_k) && m == (_m)
//        case let .Mul(x):
//            guard case let .Mul(y) = rhs else { return false }
//            return x.l == (y.l) && x.r == (y.r)
//        case let .Add(x):
//            guard case let .Add(y) = rhs else { return false }
//            return x.l == (y.l) && x.r == (y.r)
//        case let .a(x):
//            guard case let .a(y) = rhs else { return false }
//            guard x.dim == y.dim else { return false }
//            return zip(y.e, x.e).allSatisfy { (rowX, rowY) -> Bool in
//                zip(rowX, rowY).allSatisfy { (_x,_y) -> Bool in
//                    _x == (_y)
//                }
//            }
//        }
//    }
//}
