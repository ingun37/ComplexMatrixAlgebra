struct ComplexMatrixAlgebra {
    var text = "Hello, World!"
}
//struct MEq: Equatable{
//    static func == (lhs: MEq, rhs: MEq) -> Bool {
//        return lhs.m.eq(rhs.m)
//    }
//    
//    let m:MAlg
//    
//}
//protocol MAlg {
//    func eval() -> MAlg
//    func eq(_ to:MAlg) -> Bool
//}
//extension MAlg {
//    var equatable: MEq {
//        return MEq(m: self)
//    }
//}
//struct MScale: MAlg {
//    func eval() -> MAlg {
//        let k = self.k.eval()
//        let m = self.m.eval()
//        if let m = m as? Matrix {
//            let newElems = m.elems.map { (row) in
//                row.map { (f) in
//                    CMul(l: k, r: f).eval()
//                }
//            }
//            return Matrix(elems: newElems)
//        }
//        return MScale(k: k, m: m)
//    }
//    
//    func eq(_ to: MAlg) -> Bool {
//        guard let to = to as? MScale else { return false }
//        return k.eq(to.k) && m.eq(to.m)
//    }
//    
//    let k: CField
//    let m:MAlg
//}
//struct Matrix:MAlg {
//    func eval() -> MAlg {
//        let newElems = elems.map { (row) in
//            row.map { (f) in
//                f.eval()
//            }
//        }
//        return Matrix(elems: newElems)
//    }
//    
//    func eq(_ to: MAlg) -> Bool {
//        guard let to = to as? Matrix else { return false }
//        guard elems.count == to.elems.count else { return false }
//        
//        return zip(elems, to.elems).allSatisfy { (rowL, rowR) in
//            rowL.count == rowR.count && zip(rowL, rowR).allSatisfy { (l,r) in
//                l.eq(r)
//            }
//        }
//        
//    }
//    
//    let elems: [[CField]]
//}
//protocol MBinary:MAlg {
//    var l:MAlg { get }
//    var r:MAlg { get }
//}
//
//struct MAdd:MBinary, AbelianGroupBinary {
//    static func evalTerms<T:Collection>(head:MAlg, tail:T) -> MAlg where T.Element == MAlg{
//        let terms = [head] + tail
//        for i in 0..<terms.count {
//            for j in (0..<terms.count).without(i) {
//                let l = terms[i]
//                let r = terms[j]
//                if let l = l as? Matrix, let r = r as? Matrix {
//                    if l.dim == r.dim {
//                        let newElems = zip(l.elems, r.elems).map { (rowL, rowR) in
//                            zip(rowL, rowR).map { (x,y) in
//                                CAdd(l: x, r: y).eval()
//                            }
//                        }
//                        let resultMat = Matrix(elems: newElems)
//                        let newTerms = (0..<terms.count).without(i, j).map({terms[$0]})
//                        return evalTerms(head: resultMat, tail: newTerms)
//                    }
//                }
//            }
//        }
//        return tail.reduce(head) { (x, fx) in
//            MAdd(l: x, r: fx)
//        }
//    }
//    func eval() -> MAlg {
//        let l = self.l.eval()
//        let r = self.r.eval()
//        let terms = MAdd.flatTerms(m: l) + MAdd.flatTerms(m: r)
//        
//        return MAdd.evalTerms(head: terms.first!, tail: terms.dropFirst())
//    }
//    
//    func eq(_ to: MAlg) -> Bool {
//        guard let to = to as? MAdd else { return false }
//        return l.eq(to.l) && r.eq(to.r)
//    }
//    
//    let l: MAlg
//    let r: MAlg
//}
//struct MMul:MBinary {
//    func eval() -> MAlg {
//        let l = self.l.eval()
//        let r = self.r.eval()
//        if let l = l as? Matrix {
//            if let r = r as? Matrix {
//                if l.colLen == r.rowLen && l.rowLen == r.colLen {
//                    let newElems = l.rows.map { (lrow) in
//                        r.cols.map { (rcol) in
//                            zip(lrow, rcol).map { (x,y) in CMul(l: x, r: y) }.reduce(Complex.zero) { (x, fx) in CAdd(l: x, r: fx) }.eval()
//                        }
//                    }
//                    return Matrix(elems: newElems)
//                }
//            }
//        }
//        return MMul(l: l, r: r)
//    }
//    
//    func eq(_ to: MAlg) -> Bool {
//        guard let to = to as? MMul else { return false }
//        return l.eq(to.l) && r.eq(to.r)
//    }
//    
//    let l: MAlg
//    let r: MAlg
//}
//
