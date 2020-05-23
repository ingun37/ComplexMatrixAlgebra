//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/20.
//

import Foundation
protocol AbelianBasis:Basis {
    static func + (l:Self, r:Self)->Self
    static prefix func - (l:Self)->Self
    static var Zero:Self {get}
}

struct AbelianAddition<A:Abelian>:CommutativeBinary {
    func match(_ a: A) -> Self? {
        if case let .Add(bin) = a.abelianOp {
            return bin
        }
        return nil
    }
    
    let l: A
    let r: A
}
indirect enum AbelianOperator<A:Abelian>:Operator {
    case Add(AbelianAddition<A>)
    case Subtract(A,A)
    case Negate(A)
    
    func eval() -> A {
        switch self {
        case let .Add(bin):
            return operateAbelianAdd(bin.l.eval(), bin.r.eval())
        case let .Subtract(l, r):
            return (l + -r).eval()
        case let .Negate(x):
            let x = x.eval()
            switch x.element {
            case let .Basis(x):
                return .init(element: .Basis(-x))
            default:
                break
            }
            switch x.abelianOp {
            case let .Add(bin):
                return ((-bin.l) + (-bin.r)).eval()
            case let .Negate(x):
                return x.eval()
            case let .Subtract(l, r):
                return (r - l).eval()
            default: break
            }
        default: break
        }
        return .init(abelianOp: self)
    }
}
protocol Abelian:Algebra where B:AbelianBasis {
    typealias AbelianO = AbelianOperator<Self>
    init(abelianOp:AbelianO)
    var abelianOp: AbelianO? {get}
}
extension Abelian {
    static func + (l:Self, r:Self)-> Self {
        return .init(abelianOp: .Add(.init(l:l, r:r)))
    }
    static func - (lhs: Self, rhs: Self) -> Self {
        return .init(abelianOp: .Subtract(lhs, rhs))
    }
    static prefix func - (l:Self)-> Self {
        return .init(abelianOp: .Negate(l))
    }
    static var Zero:Self {
        return .init(element: (.Basis(B.Zero)))
    }
}
func flatAbelianAdd<A:Abelian>(_ x:A)-> List<A> {
    return flatAlgebra(x) { (x) -> [A] in
        if case let .Add(bin) = x.abelianOp {
            return [bin.l,bin.r]
        } else {
            return []
        }
    }
}

func operateAbelianAdd<A:Abelian>(_ x:A, _ y:A)-> A {
    return operateCommutativeBinary({ (_ l: A, _ r: A) -> A? in
        if l == A.Zero  {
            return r
        } else if case let (.Basis(l), .Basis(r)) = (l.element,r.element) {
            return A(element: .Basis(l + r))
        } else if (-l).eval() == (r) {
            return A.Zero
        } else {
            return nil
        }
    }, flatAbelianAdd(x) + flatAbelianAdd(y)).reduce { (l, r) -> A in A(abelianOp: .Add(.init(l:l, r:r))) }
}
