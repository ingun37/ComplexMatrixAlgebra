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
    init(_ h:T) {
        head = h
        tail = []
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
    func reduce<R>(head transHead: (T)->R, _ reducer:(R, T)->R) -> R {
        return tail.reduce(transHead(head)) { (l, r) in
            reducer(l,r)
        }
    }
    func fzip(_ with:List<T>) -> List<(T,T)> {
        let newHead = (head, with.head)
        let newTail = zip(tail, with.tail)
        return List<(T,T)>(newHead, newTail)
    }
}
extension List: Equatable where T:Equatable {
    
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
        return Real(op: RealOperable(ringOp: .Number(self)))// Real(op: .Number(self))
    }
}
extension ComplexNumber {
    var f: Complex {
        return Complex(op: ComplexOperable(ringOp: .Number(self)))
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
        return F(op: F.O(fieldOp: .Var(self)))
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
        if case let .Add(l,r) = x.op.ringOp {
            return [l,r]
        } else {
            return []
        }
    }
}
func flatMul<A:Field>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Mul(l,r) = x.op.ringOp {
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
        if l == A.Zero {
            return r
        } else if case let (.Number(l), .Number(r)) = (l.op.ringOp,r.op.ringOp) {
            return A.O.RingO.Number(l + r).sum.asField
        } else if (-l).eval().sameField(r) {
            return A.Zero
        } else {
            return nil
        }
    }, flatAdd(x) + flatAdd(y)).reduce(+)
}


func operateFieldMul<A:Field>(_ x:A, _ y:A)-> A {
    return operateCommutativeBinary({ (_ l: A, _ r: A) -> A? in
        if case let .Add(x, y) = l.op.ringOp {
            let xr = x * r
            let yr = y * r
            return (xr + yr).eval()
        } else if l == A.Id {
            return r
        } else if l == A.Zero {
            return A.Zero
        } else if case let (.Number(ln), .Number(rn)) = (l.op.ringOp,r.op.ringOp) {
            return A.O.RingO.Number(ln * rn).sum.asField.eval()
        }
        switch (l.op.fieldOp,r.op.fieldOp) {
        case (.Power(base: let lbase, exponent: let lexp), .Power(base: let rbase, exponent: let rexp)):
            if lbase.sameField(rbase) {
                return A.O.O.Power(base: lbase, exponent: lexp + rexp).f.eval()
            }
        default:
            return nil
        }
        return nil
    }, flatMul(x) + flatMul(y)).reduce(*)
}
