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
struct Mat<F:Field> {
    let e:List<List<F>>
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
    func fit(to:(Int,Int))-> Self {
        let maxRow = to.0
        let maxCol = to.1
        let template = List(0, (1..<maxRow)).fmap { (r) in
            List(0,(1..<maxCol)).fmap({c in (r,c)})
        }
        let newE = template.fmap { (row) in
            row.fmap { (row,col) in
                self.e.all.at(row, or: List(F.Zero)).all.at(col, or: F.Zero)
            }
        }
        return .init(e: newE)
    }
    var id:Self {
        let mx = max(rowLen, colLen)
        let newE = List(0, (1..<mx)).fmap { (row) in
            List(0, (1..<mx)).fmap { (col) in
                row == col ? F.Id : F.Zero
            }
        }
        return .init(e: newE)
    }
    static func * (l:F, r:Self)->Self {
        let newE = r.e.fmap { (row) in
            row.fmap { (e) in
                (l*e).eval()
            }
        }
        return .init(e: newE)
    }
    static func + (l:Self, r:Self)->Self {
        let maxRow = max(l.rowLen, r.rowLen)
        let maxCol = max(l.colLen, r.colLen)
        let dim = (maxRow, maxCol)
        let newL = l.fit(to: dim)
        let newR = r.fit(to: dim)
        
        let newElements = newL.e.fzip(newR.e).fmap { (l,r) in
            l.fzip(r).fmap(+).fmap({$0.eval()})
        }
        return (.init(e: newElements))
    }
    static func == (l:Self, r:Self)->Bool {
        guard l.dim == r.dim else { return false }
        return l.e.fzip(r.e).all.allSatisfy { (x,y) -> Bool in
            x.fzip(y).all.allSatisfy { (x,y) -> Bool in
                x == y
            }
        }
    }
}
enum MatrixBasis<F:Field>:AbelianBasis {
    static var Zero: MatrixBasis<F> {return .zero}
    
    static func == (lhs: MatrixBasis<F>, rhs: MatrixBasis<F>) -> Bool {
        switch (lhs,rhs) {
        case let (.zero,.zero): return true
        case let (.zero,.id(x)): return x == .Zero
        case let (.zero,.Matrix(m)): return m.e.all.allSatisfy({$0.all.allSatisfy({$0 == .Zero})})

        case let (.id(x),.zero): return x == .Zero
        case let (.id(x),.id(y)): return x == y
        case let (.id(f),.Matrix(m)): return m.id.dim == m.dim && m == (f * m.id)

        case let (.Matrix(m),.zero): return rhs == lhs
        case let (.Matrix(m),.id(y)): return rhs == lhs
        case let (.Matrix(x),.Matrix(y)): return x == y
        }
    }
    
    case zero
    case id(F)
    case Matrix(Mat<F>)
    
    static prefix func - (l: Self) -> Self {
        switch l {
        case .zero: return .zero
        case let .id(f): return .id((-f).eval())
        case let .Matrix(e):
            let newE = e.e.fmap { (row) in
                row.fmap { (e) in
                    (-e).eval()
                }
            }
            return .Matrix(.init(e: newE))
        }
    }
    
//    static func * (l:MatrixBasis, r:MatrixBasis)->MatrixBasis {
//        let mx = max(l.colLen, r.rowLen)
//        let newL = l.fit(to: (l.rowLen, mx))
//        let newR = r.fit(to: (mx, r.colLen))
//        let newElems = newL.rows.fmap { (lrow) in
//            newR.cols.fmap { (rcol) in
//                lrow.fzip(rcol).fmap(*).reduce(+).eval()
//            }
//        }
//        return MatrixBasis(e: newElems)
//    }
    
    static func * (l:F, r:MatrixBasis)->MatrixBasis {
        switch r {
        case .zero: return .zero
        case let .id(f): return .id((l*f).eval())
        case let .Matrix(e):
            return .Matrix(l * e)
        }

    }
    
    static func + (l:MatrixBasis, r:MatrixBasis)->MatrixBasis {
        switch (l,r) {
        case let (.zero, x): return x
        case let (x, .zero): return x
        case let (.id(f),.id(ff)): return .id((f+ff).eval())
        case let (.id(f),.Matrix(m)):
            return .Matrix( (f * m.id) + m)
        case let (.Matrix(m),.id(f)):
            return .Matrix(m + (f * m.id))
        case let (.Matrix(l),.Matrix(r)):
            return .Matrix(l + r)
        }
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
                    return (s * m).matrix
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


