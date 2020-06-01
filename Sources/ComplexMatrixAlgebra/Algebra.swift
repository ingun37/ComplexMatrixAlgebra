//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit
public indirect enum Element<B:Basis>:Hashable {
    case Basis(B)
    case Var(String)
}
public protocol Operator:Hashable {
    associatedtype A:Algebra
    func eval() -> A
}
public indirect enum Construction<A:Algebra>: Hashable {
    case e(A.E)
    case o(A.O)
}
//TODO: Change once accepted: https://forums.swift.org/t/accepted-se-0280-enum-cases-as-protocol-witnesses/34850
public protocol Algebra: Hashable {
    associatedtype B:Basis
    associatedtype O:Operator where O.A == Self
    typealias E = Element<B>

    init(_ c:Construction<Self>)
    var c: Construction<Self> {
        get
    }
    
    /// Reason why not <Self, Self> is that theres inexplicable bug that it crashes with KEY_TYPE_OF_DICTIONARY_VIOLATES_HASHABLE_REQUIREMENTS
    static var cache:Dictionary<Int, Self>? {get set}
}

let lock = NSLock()

extension Algebra {
    var element:E? {
        switch c {
        case let .o(o): return nil
        case let .e(e): return e
        }
    }
    var o:O? {
        switch c {
        case let .o(o): return o
        case let .e(e): return nil
        }
    }
    func eval() -> Self {
        
        var cached:Self?
        lock.lock()
        cached = Self.cache?[self.hashValue]
        lock.unlock()
        
        if let cached = cached {
            return cached
        }
        
        let result = o?.eval() ?? self
        
        lock.lock()
        Self.cache?[self.hashValue] = result
        lock.unlock()
        return result
    }
    init(element:E) {
        self.init(.e(element))
    }
}
public protocol Basis:Hashable {}

func commuteSame<C:Collection, T:Algebra>(_ xs:C, _ ys:C) -> Bool where C.Element == T, C.Index == Int{
    guard xs.count == ys.count else { return false }
    let len = xs.count
    if len == 0 { return true }
    let aa = (0..<len).flatMap({i in (0..<len).map({(i,$0)})})
    if let match = aa.first(where: { xs[$0] == (ys[$1]) }) {
        return commuteSame(xs.without(at:match.0), ys.without(at: match.1))
    } else {
        return false
    }
    
}
func commuteEqual<C:Collection, T:Algebra>(_ xs:C, _ ys:C) -> Bool where C.Element == T, C.Index == Int{
    guard xs.count == ys.count else { return false }
    let len = xs.count
    if len == 0 { return true }
    let aa = (0..<len).flatMap({i in (0..<len).map({(i,$0)})})
    if let match = aa.first(where: { xs[$0] == ys[$1] }) {
        return commuteEqual(xs.without(at:match.0), ys.without(at: match.1))
    } else {
        return false
    }
    
}
public protocol AssociativeBinary:Hashable {
    associatedtype A:Algebra
    var l: A { get }
    var r: A { get }
    func match(_ a:A)-> Self?
    init(l:A, r:A)
}
extension AssociativeBinary {
    var x: A { return l }
    var y: A { return r }
    func flat()->List<A> {
        return (match(l)?.flat() ?? List(l)) + (match(r)?.flat() ?? List(r))
    }
    public static func == (x:Self, y:Self)-> Bool {
        let xs = x.flat()
        let ys = y.flat()
        guard xs.all.count == ys.all.count else { return false }
        return xs.fzip(ys).fmap(==).reduce({$0 && $1})
//        return zip(xs, ys).map(==).reduce(true, {$0 && $1})
    }
    var eachEvaled: Self {
        return .init(l: l.eval(), r: r.eval())
    }
}
public protocol CommutativeBinary:AssociativeBinary {}
extension CommutativeBinary {
    public static func == (x:Self, y:Self)-> Bool {
        let xs = x.flat()
        let ys = y.flat()
        return commuteEqual(xs.all, ys.all)
    }
}
public protocol AssociativeMultiplication:AssociativeBinary where A:MMonoid {}
extension AssociativeMultiplication {
    public func match(_ a: A) -> Self? {
        if case let .Mul(b) = a.mmonoidOp {
            return .init(l: b.l, r: b.r)
        }
        return nil
    }
}
public protocol CommutativeMultiplication:AssociativeMultiplication, CommutativeBinary where A:MAbelian {}

protocol CommutativeAddition:CommutativeBinary where A:Abelian {}
extension CommutativeAddition {
    public func match(_ a: A) -> Self? {
        if case let .Add(b) = a.amonoidOp {
            return .init(l: b.l, r: b.r)
        }
        return nil
    }
}
