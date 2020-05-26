//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/20.
//

import Foundation
protocol AbelianBasis:AMonoidBasis {
    static prefix func - (l:Self)->Self
}

indirect enum AbelianOperator<A:Abelian>:Operator {
    case Monoid(A.AMonO)
    case Subtract(A,A)
    case Negate(A)
    
    func eval() -> A {
        switch self {
        case let .Monoid(mon):
            if case let .Add(bin) = mon {
                let l = bin.l.eval()
                let r = bin.r.eval()
                
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
                    let aeval2 = alter2.eval()
                    if alter2 != aeval2 {
                        return (aeval2 + y).eval()
                    }
                }
                if case let .Add(radd) = r.amonoidOp {
                    let (x,y) = (radd.x, radd.y)
                    // commutativity l+(x+y) = x+(l+y)
                    let alter1 = l+y
                    let aeval1 = alter1.eval()
                    if alter1 != aeval1 {
                        return (x+aeval1).eval()
                    }
                }
            }
            return mon.eval()
        case let .Subtract(l, r):
            return (l + -r).eval()
        case let .Negate(x):
            let x = x.eval()
            switch x.element {
            case let .Basis(x): return .init(element: .Basis(-x))
            default: break
            }
            switch x.amonoidOp {
            case let .Add(bin): return ((-bin.l) + (-bin.r)).eval()
            default: break
            }
            switch x.abelianOp {
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
protocol Abelian:AMonoid where B:AbelianBasis, ADD:CommutativeBinary {
    typealias AbelianO = AbelianOperator<Self>
    init(abelianOp:AbelianO)
    var abelianOp: AbelianO? {get}
}
extension Abelian {
    static func - (lhs: Self, rhs: Self) -> Self {
        return .init(abelianOp: .Subtract(lhs, rhs))
    }
    static prefix func - (l:Self)-> Self {
        return .init(abelianOp: .Negate(l))
    }
    var amonoidOp: AMonO? {
        switch abelianOp {
        case let .Monoid(m): return m
        default: return nil
        }
    }
    init(amonoidOp: AMonO) {
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
