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

struct MatrixBasis<N:NatRep, F:Field>:RingBasis {
    static prefix func - (l: Self) -> Self {
        let newE = l.e.fmap { (row) in
            row.fmap { (e) in
                -e
            }
        }
        return MatrixBasis(e: newE)
    }
    
    
    static var Zero: Self {
        let r = (0..<N.n).decompose() ?? List(0)
        let ee = r.fmap { (_) in
            r.fmap { (_) in
                F.Zero
            }
        }
        return MatrixBasis(e: ee)
    }
    
    static var Id: Self {
        let _2d = (0..<N.n).map { (r) in
            (0..<N.n).map { (c) in
                r == c ? F.Id : F.Zero
            }.decompose()!
        }.decompose()!
        return MatrixBasis(e: _2d)
    }
    
    let e:List<List<F>>
    
    static func * (l:MatrixBasis, r:MatrixBasis)->MatrixBasis {
        let newElems = l.rows.fmap { (lrow) in
            r.cols.fmap { (rcol) in
                lrow.fzip(rcol).fmap(*).reduce(+).eval()
            }
        }
        return MatrixBasis(e: newElems)
    }
    
    static func * (l:F, r:MatrixBasis)->MatrixBasis {
        let newE = r.e.fmap { (row) in
            row.fmap { (e) in
                (l*e).eval()
            }
        }
        return MatrixBasis(e: newE)
    }
    
    static func + (l:MatrixBasis, r:MatrixBasis)->MatrixBasis {
        let newElements = l.rows.fzip(r.rows).fmap { (l,r) in
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


indirect enum MatrixOp<N:NatRep>:RingOperable {
    init(basisOp: BasisOperators<Matrix<N>>) {
        self = .Ring(.Basis(basisOp))
    }
    
    var basisOp: BasisOperators<Matrix<N>>? {
        switch self {
        case let .Ring(.Basis(b)):
            return b
        default:
            return nil
        }
    }
    
    typealias RingO = RingOperators<Matrix<N>>
    init(ringOp: RingO) {
        self = .Ring(ringOp)
    }
    
    var ringOp: RingO? {
        switch self {
        case let .Ring(r):
            return r
        default:
            return nil
        }
    }
    
    typealias A = Matrix<N>
    
    case Ring(RingO)
    case Scale(Complex, A)
}

struct Matrix<N:NatRep>:Ring {
    typealias B = MatrixBasis<N,Complex>

    func eval() -> Matrix {
        switch op {
        case let .Scale(s, m):
            let s = s.eval()
            let m = m.eval()
            switch m.op {
            case let .Scale(s2, m):
                return MatrixOp<N>.Scale(s*s2, m).ring.eval()
            case let .Ring(ro):
                switch ro {
                case let .Add(ml, mr):
                    return ((s * ml) + (s * mr)).eval()
                case let .Basis( .Number(m)):
                    return m.e.fmap { (row) in
                        row.fmap { (e) in
                            (s * e).eval()
                        }
                    }.mat().asNumber(Self.self).op.ring
                default:
                    return s * m
                }
            }
        case .Ring(_):
            return evalRing()
        }
    }
    
    func same(_ to: Matrix) -> Bool {
        return sameRing(to)
    }
    
    static func * (l:Complex, r:Self)-> Self {
        return MatrixOp<N>.Scale(l, r).ring
    }
    let op: MatrixOp<N>
    
}

extension List where T == List<Complex> {
    func mat<N:NatRep>()-> MatrixBasis<N,Complex> {
        return MatrixBasis(e: self)
    }
}
protocol NatRep:Equatable {
    static var n:Int {get}
}
struct N1:NatRep { static var n = 1 }
struct N2:NatRep { static var n = 2 }
struct N3:NatRep { static var n = 3 }
struct N4:NatRep { static var n = 4 }
struct N5:NatRep { static var n = 5 }
struct N6:NatRep { static var n = 6 }
struct N7:NatRep { static var n = 7 }
struct N8:NatRep { static var n = 8 }
struct N9:NatRep { static var n = 9 }
