//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/20.
//

import Foundation
public protocol AbelianBasis:AMonoidBasis {
    static prefix func - (l:Self)->Self
}

public indirect enum AbelianOperator<A:Abelian>:Operator {
    case Monoid(A.AMonO)
    case Subtract(A,A)
    case Negate(A)
    
    public func eval() throws -> A {
        switch self {
        case let .Monoid(mon):
            if case let .Add(bin) = mon {
                let l = try bin.l.eval()
                let r = try bin.r.eval()
                
                if case let .Negate(l) = l.abelianOp {
                    if l == r {
                        return .Zero
                    }
                }
                if case let .Negate(r) = r.abelianOp {
                    if l == r {
                        return .Zero
                    }
                }
                
                if case let .Add(ladd) = l.amonoidOp {
                    let (x,y) = (ladd.x, ladd.y)
                    
                    // commutativity (x+y)+r = (x+r)+y
                    let alter2 = x + r
                    let aeval2 = try alter2.eval()
                    if alter2 != aeval2 {
                        return try (aeval2 + y).eval()
                    }
                }
                if case let .Add(radd) = r.amonoidOp {
                    let (x,y) = (radd.x, radd.y)
                    // commutativity l+(x+y) = x+(l+y)
                    let alter1 = l+y
                    let aeval1 = try alter1.eval()
                    if alter1 != aeval1 {
                        return try (x+aeval1).eval()
                    }
                }
            }
            return try mon.eval()
        case let .Subtract(l, r):
            return try (l + -r).eval()
        case let .Negate(x):
            let x = try x.eval()
            switch x.element {
            case let .Basis(x): return try .init(element: .Basis(-x))
            default: break
            }
            switch x.amonoidOp {
            case let .Add(bin): return try ((-bin.l) + (-bin.r)).eval()
            default: break
            }
            switch x.abelianOp {
            case let .Negate(x):
                return x
            case let .Subtract(l, r):
                return try (r - l).eval()
            default: break
            }
        default: break
        }
        return .init(abelianOp: self)
    }
}
public protocol Abelian:AMonoid where B:AbelianBasis, ADD:CommutativeBinary {
    typealias AbelianO = AbelianOperator<Self>
    init(abelianOp:AbelianO)
    var abelianOp: AbelianO? {get}
}
extension Abelian {
    public static func - (lhs: Self, rhs: Self) -> Self {
        return .init(abelianOp: .Subtract(lhs, rhs))
    }
    public static prefix func - (l:Self)-> Self {
        return .init(abelianOp: .Negate(l))
    }
    public var amonoidOp: AMonO? {
        switch abelianOp {
        case let .Monoid(m): return m
        default: return nil
        }
    }
    public init(amonoidOp: AMonO) {
        self.init(abelianOp: .Monoid(amonoidOp))
    }
}
func flatAbelianAdd<A:Abelian>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Add(bin) = x.amonoidOp {
            return [bin.l,bin.r]
        } else {
            return []
        }
    }
}
