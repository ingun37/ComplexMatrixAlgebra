//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit
indirect enum Element<B:Basis>:Equatable {
    case Basis(B)
    case Var(String)
}
protocol Operator:Equatable {
    associatedtype A:Algebra
    func eval() -> A
}
indirect enum Construction<A:Algebra>: Equatable {
    case e(A.E)
    case o(A.O)
}
//TODO: Change once accepted: https://forums.swift.org/t/accepted-se-0280-enum-cases-as-protocol-witnesses/34850
protocol Algebra: Equatable {
    associatedtype B:Basis
    associatedtype O:Operator where O.A == Self
    typealias E = Element<B>

    init(_ c:Construction<Self>)
    var c: Construction<Self> {
        get
    }
}
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
        return o?.eval() ?? self
    }
    init(element:E) {
        self.init(.e(element))
    }
}
protocol Basis:Equatable {}

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
protocol AssociativeBinary:Equatable {
    associatedtype A:Algebra
    var l: A { get }
    var r: A { get }
    func match(_ a:A)-> Self?
    init(l:A, r:A)
}
extension AssociativeBinary {
    var x: A { return l }
    var y: A { return r }
    func flat()->[A] {
        return (match(l)?.flat() ?? [l]) + (match(r)?.flat() ?? [r])
    }
    static func == (x:Self, y:Self)-> Bool {
        let xs = x.flat()
        let ys = y.flat()
        guard xs.count == ys.count else { return false }
        return zip(xs, ys).map(==).reduce(true, {$0 && $1})
    }
}
protocol CommutativeBinary:AssociativeBinary {}
extension CommutativeBinary {
    static func == (x:Self, y:Self)-> Bool {
        let xs = x.flat()
        let ys = y.flat()
        return commuteEqual(xs, ys)
    }
}
