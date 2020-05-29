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
    func at(_ i:Index, or:Element)->Element {
        if self.indices.contains(i) {
            return self[i]
        } else {
            return or
        }
    }
}
struct List<T> {
    static func rng(_ limit:Int)-> List<Int> {
        return List<Int>(0, (1..<limit))
    }
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
    static func + <C:Collection>(lhs: List, rhs: C) -> List where C.Element == T {
        return List(lhs.head, lhs.tail + rhs)
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
    func reduceR<R>(_ i:(T)->R, _ eval: (T,R)->R)->R {
        if let t = tail.decompose() {
            return eval(head, t.reduceR(i, eval))
        } else {
            return i(head)
        }
    }
    var reversed:List<T> {
        return reduceR({ (last) -> List<T> in
            List(last)
        }) { (last, ls) -> List<T> in
            ls + List(last)
        }
    }
}

extension List: Equatable where T: Equatable {}

extension List: Hashable where T:Hashable {}

extension List where T:Algebra {
    func grouped()-> List<List<T>> {
        let (us, others) = tail.seperate { (x) in head == (x) }
        let we = List(head, us)
        if let otherGroup = others.decompose() {
            return List<List<T>>(we) + otherGroup.grouped()
        } else {
            return List<List<T>>(we)
        }
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




extension Int {
    var real: RealBasis {
        return .N(self)
    }
    func on(_ deno:Int)-> Rational<Int> {
        return Rational(self, deno)
    }
    func complex(i:Int) -> ComplexBasis {
        return ComplexBasis(r: real.f, i: i.real.f)
    }
}
extension RealBasis {
    var f: Real {
        return Real(element: .Basis(self))
        
//        return Real(op: RealOperable(ringOp: .Number(self)))// Real(op: .Number(self))
    }
}
extension ComplexBasis {
    var f: Complex {
        return Complex(element: .Basis(self))
//        return Complex(op: .init(basisOp: .Number(self)))
//        return Complex(op: .Number(self))
    }
}
//extension FieldSet{
//    func f<F:_Field>() -> F where F.Num == Self {
//        return F(op: .Number(self))
//    }
//}
extension Double {
    var real: RealBasis {
        return (RealBasis.R(self))
    }
}
extension Rational where T == Int {
    var real: RealBasis {
        return (.Q(self))
    }
    func complex(i:Rational) -> ComplexBasis {
        return (ComplexBasis(r: real.f, i: i.real.f))
    }
}
extension String {
    func f<F:Field>() -> F {
        return F(element: .Var(self))
        
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

func join<T>(optionals:[T?])->[T]? {
    return optionals.reduce([]) { (l, e)->[T]? in
        guard let l = l else {return nil}
        switch e {
        case .none:
            return nil
        case let .some(v):
            return l + [v]
        }
    }
}
