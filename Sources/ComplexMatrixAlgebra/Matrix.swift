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
public struct Mat<F:Field>:Hashable {
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
    public static func == (l:Self, r:Self)->Bool {
        guard l.dim == r.dim else { return false }
        return l.e.fzip(r.e).all.allSatisfy { (x,y) -> Bool in
            x.fzip(y).all.allSatisfy { (x,y) -> Bool in
                x == y
            }
        }
    }
    static func * (l:Self, r:Self)->Self {
        let mx = max(l.colLen, r.rowLen)
        let newL = l.fit(to: (l.rowLen, mx))
        let newR = r.fit(to: (mx, r.colLen))
        let newElems = newL.rows.fmap { (lrow) in
            newR.cols.fmap { (rcol) in
                lrow.fzip(rcol).fmap(*).reduce(+).eval()
            }
        }
        return .init(e: newElems)
    }
    var transposed:Self {
        return Mat(e: cols)
    }
    func without(col:Int)->Self? {
        if let newCols = cols.all.without(at: col).decompose() {
            return Self(e: newCols).transposed
        } else {
            return nil
        }
    }
    func without(row:Int, col:Int) -> Self?  {
        if let remainRows = rows.all.without(at: row).decompose() {
            if let remainCols = Mat(e: remainRows).cols.all.without(at: col).decompose() {
                return Mat(e: remainCols).transposed
            }
        }
        return nil
    }
    var determinant:F {
        return List<Int>.rng(colLen).fmap { (c)->F in
            if let subMatrix = self.without(row: 0, col: c) {
                return (F._Id^F.B.whole(n: c).asNumber(F.self)) * self.col(c).head * subMatrix.determinant
            } else {
                return self.row(0).all[c]
            }
        }.reduce(+).eval()
    }
    func cofactor(i:Int, j:Int)-> F? {
        if let detAij = without(row: i, col: j)?.determinant {
            let co = F._Id^F.B.whole(n: i+j).asNumber(F.self)
            return co * detAij
        } else {
            return nil
        }
    }
    var inversed:Self? {
        let cofacs = join(optionals: (0..<rowLen).map { (row) in
            join(optionals: (0..<colLen).map { (col) in
                cofactor(i: col, j: row)
            })?.decompose()
        })?.decompose()
        guard let cofactors = cofacs else { return nil }
        let coMat = Mat(e: cofactors)
        return (~determinant).eval() * coMat
    }
    var echelon:Self {
        let nonZeroTopEntry = rows.reduceR({ (end) in
            List(end)
        }, { (prev, newRows) in
            if prev.head == .Zero {
                return newRows + List(prev)
            } else {
                return List(prev) + newRows
            }
        })
        
        if nonZeroTopEntry.head.head == .Zero {
            let nx = without(col: 0)
            if let nx_rdc = nx?.echelon {
                let newRows = nx_rdc.rows.fmap({List(.Zero) + $0})
                return .init(e: newRows)
            } else {
                return self
            }
        }
        guard let Trows = nonZeroTopEntry.tail.decompose() else { return self }
        let h = nonZeroTopEntry.head
        let Zrows = Trows.fmap { (Tn) -> List<F> in
            let bn = Tn.head
            let co = (-bn)/h.head
            return Tn.fzip(h).fmap({(t,h) in (t + (co * h)).eval()})
        }
        
        let Z = Mat(e: Zrows).echelon
        
        return Mat(e: List(h) + Z.rows)
    }
    
    var reducedEchelon:Self {
        let ech = echelon
        var rows = ech.rows.all
        for i in (0..<rows.count).reversed() {
            let row = rows[i]
            guard let entryIdx = row.entryIdx else { continue }
            let entry = row.all[entryIdx]
            let row2 = ~entry * row
            rows[i] = row2
            for j in (0..<i) {
                let rowj = rows[j]
                rows[j] = rowj.subtract(rowj.all[entryIdx] * row2)
            }
        }
        return Mat(e: rows.decompose()!)
    }
}


public struct Matrix<F:Field>:Ring {
    public static var cache: Dictionary<Int, Matrix<F>>? {
        get {
            return nil
        }
        set {
            
        }
    }
    
    public typealias ADD = MatrixAddition<F>
    public typealias MUL = MatrixMultiplication<F>
    
    public init(_ c: Construction<Matrix>) {
        self.c = c
    }
    
    public let c: Construction<Matrix>
    
    public typealias B = MatrixBasis<F>
    public typealias O = MatrixOp<F>
    
    
    public init(ringOp: RingOp) {
        c = .o(.Ring(ringOp))
    }
    
    public var ringOp: RingOp? {
        switch o {
        case let .Ring(r): return r
        default: return nil
        }
    }

    static func * (l:F, r:Self)-> Self {
        return .init(.o(.Scale(l, r)))
    }

}




public enum MatrixBasis<F:Field>:RingBasis {
    public static var Id: MatrixBasis<F> {return .id(.Id)}
    
    public static var Zero: MatrixBasis<F> {return .zero}
    
    case zero
    case id(F)
    case Matrix(Mat<F>)
    
    public static prefix func - (l: Self) -> Self {
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
    
    public static func * (l:Self, r:Self)->Self {
        switch (l,r) {
        case let (.zero,_): return .zero
        case let (_,.zero): return .zero

        case let (.id(x),.id(y)): return .id((x * y).eval())
        case let (.id(f),.Matrix(_)): return f * r

        case let (.Matrix(_),.id(f)):   return f * l
        case let (.Matrix(x),.Matrix(y)): return .Matrix(x * y)
        }

    }
    
    public static func * (l:F, r:MatrixBasis)->MatrixBasis {
        switch r {
        case .zero: return .zero
        case let .id(f): return .id((l*f).eval())
        case let .Matrix(e):
            return .Matrix(l * e)
        }

    }
    
    public static func + (l:MatrixBasis, r:MatrixBasis)->MatrixBasis {
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
    
    var determinant:F? {
        switch self {
        case .zero: return .Zero
        case let .id(f): return nil
        case let .Matrix(m): return m.determinant
        }
    }
    
    public static func == (lhs:Self, rhs:Self)-> Bool {
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
}

extension MatrixBasis {
    var matrix:Matrix<F> {
        return .init(element: .Basis(self))
    }
}
public struct MatrixMultiplication<F:Field>:AssociativeMultiplication {
    public let l: Matrix<F>
    public let r: Matrix<F>
    public typealias A = Matrix<F>
    public init(l ll:Matrix<F>, r rr:Matrix<F>) {
        l = ll
        r = rr
    }
}
public struct MatrixAddition<F:Field>:CommutativeAddition {
    public let l: Matrix<F>
    public let r: Matrix<F>
    public typealias A = Matrix<F>
    public init(l ll:Matrix<F>, r rr:Matrix<F>) {
        l = ll
        r = rr
    }
}
public indirect enum MatrixOp<F:Field>:Operator {
    public typealias A = Matrix<F>
    public func eval() -> A {
        switch self {
        case let .Scale(s, m):
            let s = s.eval()
            let m = m.eval()
            
            switch m.o {
            case let .Scale(s2, m): return Self.Scale(s*s2, m).matrix.eval()
            default: break
            }
            
            switch m.amonoidOp {
            case let .Add(b): return ((s * b.l) + (s * b.r)).eval()
            default: break
            }
            
            switch m.element {
            case let .Basis(m): return .init(element: .Basis(s * m))
            default: break
            }
            
            return s * m
        case let .Ring(ring):
            return ring.eval()
        case let .Inverse(m):
            let m = m.eval()
            if case let .Basis(mb) = m.element {
                switch mb {
                case let .id(f): return .init(element: .Basis(.id((~f).eval())))
                case .zero: return m
                case let .Matrix(mat):
                    if let inv = mat.inversed {
                        return .init(element: .Basis(.Matrix(inv)))
                    }
                }
            }
            return .init(.o(.Inverse(m)))
        case let .Echelon(m):
            let m = m.eval()
            if case let .Basis(mb) = m.element {
                switch mb {
                case let .id(f): return .init(element: .Basis(mb))
                case .zero: return .init(element: .Basis(mb))
                case let .Matrix(m):
                    return .init(element: .Basis(.Matrix(m.echelon)))
                }
            }
            return .init(.o(.Echelon(m)))
        case let .ReducedEchelon(m):
            let m = m.eval()
            if case let .Basis(mb) = m.element {
                switch mb {
                case let .id(f): return .init(element: .Basis(mb))
                case .zero: return .init(element: .Basis(mb))
                case let .Matrix(m):
                    return .init(element: .Basis(.Matrix(m.reducedEchelon)))
                }
            }
            return .init(.o(.ReducedEchelon(m)))
        }
    }
    
    case Ring(A.RingOp)
    case Scale(F, A)
    case Inverse(A)
    case Echelon(A)
    case ReducedEchelon(A)
    var matrix:A {
        return A(.o(self))
    }
}

extension List where T:Field {
    var entryIdx:Int? {
        return all.firstIndex(where: {$0 != .Zero})
    }
    static func * (l:T, r:Self)->Self {
        return r.fmap({(l * $0).eval()})
    }
    func add(_ to:Self)->Self {
        return fzip(to).fmap(+).fmap({$0.eval()})
    }
    func subtract(_ by:Self)->Self {
        return fzip(by).fmap(-).fmap({$0.eval()})
    }
}
