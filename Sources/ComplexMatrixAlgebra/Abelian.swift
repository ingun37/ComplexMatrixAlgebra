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
            let l = bin.l.eval()
            let r = bin.r.eval()
            if l == .Zero {
                return r
            }
            if r == .Zero {
                return l
            }
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
            if case let .Basis(lb) = l.element {
                if case let .Basis(rb) = r.element {
                    return A(element: .Basis(lb + rb))
                }
            }
            if case let .Add(ladd) = l.abelianOp {
                let (x,y) = (ladd.x, ladd.y)
                // commutativity (x+y)+r = (r+y)+x
//                let alter1 = r + y
//                let aeval1 = alter1.eval()
//                if alter1 != aeval1 {
//                    return (aeval1 + x).eval()
//                }
                // commutativity (x+y)+r = (x+r)+y
                let alter2 = x + r
                let aeval2 = alter2.eval()
                if alter2 != aeval2 {
                    return (aeval2 + y).eval()
                }
            }
            if case let .Add(radd) = r.abelianOp {
                let (x,y) = (radd.x, radd.y)
                // commutativity l+(x+y) = x+(l+y)
                let alter1 = l+y
                let aeval1 = alter1.eval()
                if alter1 != aeval1 {
                    return (x+aeval1).eval()
                }
                // commutativity l+(x+y) = y+(x+l)
//                let alter2 = x+l
//                let aeval2 = alter2.eval()
//                if alter2 != aeval2 {
//                    return (y+aeval2).eval()
//                }
            }
            
            if case let .Add(ladd) = l.abelianOp {
                //associativity (x+y)+r = x+(y+r)
                let (x,y) = (ladd.x, ladd.y)
                let alter = y+r
                let aeval = alter.eval()
                if alter != aeval {
                    return (x+aeval).eval()
                }
            }
            if case let .Add(radd) = r.abelianOp {
                //associativity l+(x+y) = (l+x)+y
                let (x,y) = (radd.x, radd.y)
                let alter = l+x
                let aeval = alter.eval()
                if alter != aeval {
                    return (aeval+y).eval()
                }
            }
            return A(abelianOp: .Add(.init(l: l, r: r)))
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
