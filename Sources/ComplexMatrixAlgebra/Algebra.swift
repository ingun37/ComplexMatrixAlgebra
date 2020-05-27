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
    func flat()->List<A> {
        return (match(l)?.flat() ?? List(l)) + (match(r)?.flat() ?? List(r))
    }
    static func == (x:Self, y:Self)-> Bool {
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
protocol CommutativeBinary:AssociativeBinary {}
extension CommutativeBinary {
    static func == (x:Self, y:Self)-> Bool {
        let xs = x.flat()
        let ys = y.flat()
        return commuteEqual(xs.all, ys.all)
    }
}
protocol AssociativeMultiplication:AssociativeBinary where A:MMonoid {}
extension AssociativeMultiplication {
    func match(_ a: A) -> Self? {
        if case let .Mul(b) = a.mmonoidOp {
            return .init(l: b.l, r: b.r)
        }
        return nil
    }
    func caseMultiplicationWithId() -> A? {
        if l == .Id { return r }
        if r == .Id { return l }
        return nil
    }
    func caseBothBasis()-> A? {
        if case let .Basis(lb) = l.element {
            if case let .Basis(rb) = r.element {
                return A(element: .Basis(lb * rb))
            }
        }
        return nil
    }
    func caseAssociative() -> A? {
        if case let .Mul(lm) = l.mmonoidOp {
            //(xy)r = x(yr)
            let alter = (lm.r * r)
            let aeval = alter.eval()
            if alter != aeval {
                return (lm.l * aeval).eval()
            }
        }
        
        if case let .Mul(rm) = r.mmonoidOp {
            //l(xy) = (lx)y
            let alter = (l * rm.l)
            let aeval = alter.eval()
            if alter != aeval {
                return (aeval * rm.r).eval()
            }
        }
        return nil
    }
}
extension AssociativeMultiplication where A:Ring {
    func caseMultiplicationWithZero()-> A? {
        if l == .Zero || r == .Zero {
            return .Zero
        }
        return nil
    }
    func caseDistributive()-> A? {
        if case let .Add(ladd) = l.amonoidOp {
            return ((ladd.l * r) + (ladd.r * r)).eval()
        }
        if case let .Add(radd) = r.amonoidOp {
            return ((l * radd.l) + (l * radd.r)).eval()
        }
        return nil
    }
}
protocol CommutativeMultiplication:AssociativeMultiplication, CommutativeBinary where A:MAbelian {}
extension CommutativeMultiplication {
    func caseMultiplicationWithInverse() -> A? {
        if case let .Inverse(l) = l.mabelianOp {
            if l == r {
                return .Id
            }
        }
        if case let .Inverse(r) = r.mabelianOp {
            if l == r {
                return .Id
            }
        }
        return nil
    }
    func caseCommutative() -> A? {
        if case let .Mul(lm) = l.mmonoidOp {
            if (true) {//(x*y)*r = (x*r)*y
                let alter = (lm.x * r)
                let aeval = alter.eval()
                if alter != aeval {
                    return (aeval * lm.y).eval()
                }
            }
        }
        if case let .Mul(rm) = r.mmonoidOp {
            if (true) {//l(xy) = x(ly)
                let alter = (l * rm.y)
                let aeval = alter.eval()
                if alter != aeval {
                    return (rm.x * aeval).eval()
                }
            }
        }
        return nil
    }
}
protocol CommutativeAddition:CommutativeBinary where A:Abelian {}
extension CommutativeAddition {
    func match(_ a: A) -> Self? {
        if case let .Add(b) = a.amonoidOp {
            return .init(l: b.l, r: b.r)
        }
        return nil
    }
}
