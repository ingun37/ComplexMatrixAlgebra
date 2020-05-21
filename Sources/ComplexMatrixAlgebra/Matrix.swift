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

struct MatrixBasis<F:Field>:AbelianBasis {
    static prefix func - (l: Self) -> Self {
        let newE = l.e.fmap { (row) in
            row.fmap { (e) in
                -e
            }
        }
        return MatrixBasis(e: newE)
    }
    
    
    static var Zero: Self {
        let r = List(0)
        let ee = r.fmap { (_) in
            r.fmap { (_) in
                F.Zero
            }
        }
        return MatrixBasis(e: ee)
    }
    
    let e:List<List<F>>
    
//    static func * (l:MatrixBasis, r:MatrixBasis)->MatrixBasis {
//        let newElems = l.rows.fmap { (lrow) in
//            r.cols.fmap { (rcol) in
//                lrow.fzip(rcol).fmap(*).reduce(+).eval()
//            }
//        }
//        return MatrixBasis(e: newElems)
//    }
    
    static func * (l:F, r:MatrixBasis)->MatrixBasis {
        let newE = r.e.fmap { (row) in
            row.fmap { (e) in
                (l*e).eval()
            }
        }
        return MatrixBasis(e: newE)
    }
    
    static func + (l:MatrixBasis, r:MatrixBasis)->MatrixBasis {
        let maxRow = max(l.rowLen, r.rowLen)
        let maxCol = max(l.colLen, r.colLen)
        let template = List(0, (1..<maxRow)).fmap { (r) in
            List(0,(1..<maxCol)).fmap({c in (r,c)})
        }
        let newL = template.fmap { (row) in
            row.fmap { (row,col) in
                l.e.all.at(row, or: List(F.Zero)).all.at(col, or: F.Zero)
            }
        }
        let newR = template.fmap { (row) in
            row.fmap { (row,col) in
                r.e.all.at(row, or: List(F.Zero)).all.at(col, or: F.Zero)
            }
        }
        let newElements = newL.fzip(newR).fmap { (l,r) in
            l.fzip(r).fmap(+).fmap({$0.eval()})
        }
        return MatrixBasis(e: newElements)
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
}

extension MatrixBasis where F == Complex {
    var matrix:Matrix {
        return .init(basisOp: .Number(self))
    }
}

indirect enum MatrixOp:Equatable {
    typealias A = Matrix
    case Abelian(A.AbelianO)
    case Scale(Complex, A)
    var matrix:A {
        return A(op: self)
    }
}

struct Matrix:Abelian {
    func same(_ to: Matrix) -> Bool {
        fatalError()
    }
    init(abelianOp: AbelianO) {
        op = .Abelian(abelianOp)
    }
    
    var abelianOp: AbelianO? {
        switch op {
        case let .Abelian(abe):
            return abe
        default:
            return nil
        }
    }
    
    
    typealias B = MatrixBasis<Complex>
    typealias O = MatrixOp
    func eval() -> Matrix {
        switch op {
        case let .Scale(s, m):
            let s = s.eval()
            let m = m.eval()
            switch m.op {
            case let .Scale(s2, m):
                return O.Scale(s*s2, m).matrix.eval()
            case let .Abelian(abe):
                switch abe {
                case let .Add(ml, mr):
                    return ((s * ml) + (s * mr)).eval()
                case let .Algebra(.Number(m)):
                    let newElements = m.e.fmap { (row) in
                        row.fmap { (e) in
                            (s * e).eval()
                        }
                    }
                    return MatrixBasis(e: newElements).matrix
                default:
                    return s * m
                }
            }
        default: break
        }
        return evalAbelian()
    }
    
    
    static func * (l:Complex, r:Self)-> Self {
        return .init(op: .Scale(l, r))
    }
    let op: MatrixOp
    init(op:O) {
        self.op = op
    }
}


