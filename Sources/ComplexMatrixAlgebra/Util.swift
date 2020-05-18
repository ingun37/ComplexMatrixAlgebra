//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit
extension Collection {
    func comb2() -> [(Element, Element)] {
        guard let h = first else { return [] }
        let tail = dropFirst()
        return tail.map({($0,h)}) + tail.comb2()
    }
    func seperate<T>() -> ([T],[Element]) {
        let t = compactMap({ $0 as? T})
        let f = filter { !($0 is T) }
        return (t,f)
    }
    func seperate(_ criteria:(Element)->Bool) -> ([Element],[Element]) {
        let t = filter(criteria)
        let f = filter { !criteria($0) }
        return (t,f)
    }
    func decompose() -> List<Element>? {
        guard let x = first else { return nil }
        return List(x, dropFirst())
    }
}
struct List<T> {
    typealias Element = T
    let head:T
    let tail:[T]
    init<C:Sequence>(_ h:T, _ t:C) where C.Element == T {
        head = h
        tail = Array(t)
    }
    var pair:(T,[T]) { return (head, tail)}
    var all:[T] {return [head] + tail}
    func fmap<Q>(_ f:@escaping (T)->Q) -> List<Q> {
        return List<Q>(f(head), tail.map(f))
    }
    static func + (lhs: List, rhs: List) -> List {
        return List(lhs.head, lhs.tail + rhs.all)
    }
    func reduce(_ next:(T,T)->T) -> T  {
        return tail.reduce(head, next)
    }
}
extension Collection where Index == Int {
    
    func permutations() -> [[Element]] {
        guard let (head, tail) = decompose()?.pair else { return [[]] }
        return tail.permutations().flatMap { between(x: head, $0) }
    }
    func without(at:Int)->[Element] {
        return (0..<count).without(at).map({self[$0]})
    }
}

func between<T>(x: T, _ ys: [T]) -> [[T]] {
    guard let (head, tail) = ys.decompose()?.pair else { return [[x]] }
    return [[x] + ys] + between(x:x, tail).map { [head] + $0 }
}

extension Collection where Element:Equatable {
    func without(_ v:Element)-> [Element] {
        return filter { (e) -> Bool in
            e != v
        }
    }
    func without(_ x:Element, _ y:Element)-> [Element] {
        return without(x).without(y)
    }
}

struct Dimension:Hashable {
    let rows:Int
    let cols:Int
    init(_ rows:Int, _ cols:Int) {
        self.rows = rows
        self.cols = cols
    }
}

//extension Elements {
//    var rowLen:Int {
//        return e.count
//    }
//    var colLen:Int {
//        return e.reduce(0) { (x, fx) in x < fx.count ? fx.count : x }
//    }
//    var dim:(Int, Int) {
//        return (rowLen, colLen)
//    }
//    var dimen:Dimension {
//        return Dimension(rowLen, colLen)
//    }
//    func row(_ i:Int) -> [Complex] {
//        return e[i]
//    }
//    func col(_ i:Int) -> [Complex] {
//        return e.map { (row) in row[i] }
//    }
//    var rows:[[Complex]] {
//        return e
//    }
//    var cols:[[Complex]] {
//        return (0..<colLen).map { (coli) in col(coli) }
//    }
//}
//extension Real {
//    static var zero:Real {
//        return .Number(.N(0))
//    }
//}
//extension Complex {
//    static var zero:Complex {
//        return .Number(ComplexNumber(i: Real.zero, real: Real.zero))
//    }
//}


extension Int {
    var real: RealNumber {
        return .N(self)
    }
    func on(_ deno:Int)-> Rational<Int> {
        return Rational(self, deno)
    }
    func complex(i:Int) -> ComplexNumber {
        return ComplexNumber(r: real.f, i: i.real.f)
    }
}
extension RealNumber {
    var f: Real {
        return Real(op: RealOperatorSum(op: .Number(self)))// Real(op: .Number(self))
    }
}
extension ComplexNumber {
    var f: Complex {
        return Complex(op: ComplexOperatorSum(op: .Number(self)))
//        return Complex(op: .Number(self))
    }
}
//extension FieldSet{
//    func f<F:_Field>() -> F where F.Num == Self {
//        return F(op: .Number(self))
//    }
//}
extension Double {
    var real: RealNumber {
        return (RealNumber.R(self))
    }
}
extension Rational where T == Int {
    var real: RealNumber {
        return (.Q(self))
    }
    func complex(i:Rational) -> ComplexNumber {
        return (ComplexNumber(r: real.f, i: i.real.f))
    }
}
extension String {
    func f<F:Field>() -> F {
        return F(op: F.OpSum(op: .Var(self)))
//        return F(op: .Var(self))
    }
    var rvar: Real {
        return f()
    }
}

/**
 associative & commutative
 */
func flatAlgebra<A>(_ x:A, flatter:@escaping (A)->[A])->List<A> {
    let kx = flatter(x)
    if let y = kx.decompose() {
        return y.fmap({flatAlgebra($0, flatter: flatter)}).reduce(+)
    } else {
        return List(x, [])
    }
}
func flatAdd<A:Field>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Add(l,r) = x.op.op {
            return [l,r]
        } else {
            return []
        }
    }
}
func flatMul<A:Field>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Mul(l,r) = x.op.op {
            return [l,r]
        } else {
            return []
        }
    }
}
func operateCommutativeBinary<A>(_ trial:(A, A)->A?, _ xs:List<A> ) -> List<A> {
    return edgeMerge(_objs: xs) { (l, r) in
        if let symmetric = trial(l, r) {
            return symmetric
        } else if let symmetric = trial(r, l) {
            return symmetric
        } else {
            return nil
        }
    }
}
func operateFieldAdd<A:Field>(_ x:A, _ y:A)-> A {
    return operateCommutativeBinary({ (_ l: A, _ r: A) -> A? in
        if l == A.zero {
            return r
        } else if case let (.Number(l), .Number(r)) = (l.op.op,r.op.op) {
            return A.OpSum.O.Number(l + r).f
        } else if (-l).eval().sameField(r) {
            return A.zero
        } else {
            return nil
        }
    }, flatAdd(x) + flatAdd(y)).reduce(+)
}

func operateFieldMul<A:Field>(_ x:A, _ y:A)-> A {
    return operateCommutativeBinary({ (_ l: A, _ r: A) -> A? in
        if case let .Add(x, y) = l.op.op {
            let xr = x * r
            let yr = y * r
            return (xr + yr).eval()
        } else if l == A.id {
            return r
        } else if l == A.zero {
            return A.zero
        } else if case let (.Number(ln), .Number(rn)) = (l.op.op,r.op.op) {
            return A.OpSum.O.Number(ln * rn).f.eval()
        }
        switch (l.op.op,r.op.op) {
        case (.Power(base: let lbase, exponent: let lexp), .Power(base: let rbase, exponent: let rexp)):
            if lbase.sameField(rbase) {
                return A.OpSum.O.Power(base: lbase, exponent: lexp + rexp).f.eval()
            }
        default:
            return nil
        }
        return nil
    }, flatMul(x) + flatMul(y)).reduce(*)
}
