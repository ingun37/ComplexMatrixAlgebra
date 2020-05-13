//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit
struct REq: Equatable {
    static func == (lhs: REq, rhs: REq) -> Bool {
        return lhs.r.eq(rhs.r)
    }
    
    let r:RField
}
protocol RField {
    func eval() -> RField
    func eq(_ to:RField) -> Bool
}
extension RField {
    var equatable: REq {
        return REq(r: self)
    }
}
protocol RBinary: RField {
    var l:RField {get}
    var r:RField {get}
}
struct RAdd:RBinary {
    func eq(_ to: RField) -> Bool {
        guard let to = to as? RAdd else { return false }
        return l.eq(to.l) && r.eq(to.r)
    }
    
    func eval() -> RField {
        let l = self.l.eval()
        let r = self.r.eval()
        if let l = l as? Real {
            if let r = r as? Real {
                switch (l,r) {
                case let (.N(x), .N(y)): return Real.N(x+y)
                    
                case let (.N(x), .Q(y)): return Real.Q(y + Rational<Int>(x)).eval()
                case let (.Q(y), .N(x)): return Real.Q(y + Rational<Int>(x)).eval()
                    
                case let (.N(x), .R(y)): return Real.R(y + Double(x)).eval()
                case let (.R(y), .N(x)): return Real.R(y + Double(x)).eval()
                    
                case let (.Q(x), .Q(y)): return Real.Q(y + x).eval()
                    
                case let (.Q(x), .R(y)): return Real.R(x.doubleValue + y).eval()
                case let (.R(y), .Q(x)): return Real.R(x.doubleValue + y).eval()
                    
                case let (.R(x), .R(y)): return Real.R(y + x).eval()
                }
            }
        }
        return RAdd(l: l, r: r)
    }
    
    let l: RField
    let r: RField
}
struct RMul:RBinary {
    func eq(_ to: RField) -> Bool {
        guard let to = to as? RMul else { return false }
        return l.eq(to.l) && r.eq(to.r)
    }
    
    func eval() -> RField {
        let l = self.l.eval()
        let r = self.r.eval()
        if let l = l as? Real {
            if let r = r as? Real {
                switch (l,r) {
                case let (.N(x), .N(y)): return Real.N(x*y)
                    
                case let (.N(x), .Q(y)): return Real.Q(y * Rational<Int>(x)).eval()
                case let (.Q(y), .N(x)): return Real.Q(y * Rational<Int>(x)).eval()
                    
                case let (.N(x), .R(y)): return Real.R(y * Double(x)).eval()
                case let (.R(y), .N(x)): return Real.R(y * Double(x)).eval()
                    
                case let (.Q(x), .Q(y)): return Real.Q(y * x).eval()
                    
                case let (.Q(x), .R(y)): return Real.R(x.doubleValue * y).eval()
                case let (.R(y), .Q(x)): return Real.R(x.doubleValue * y).eval()
                    
                case let (.R(x), .R(y)): return Real.R(y * x).eval()
                }
            }
        }
        return RMul(l: l, r: r)
    }
    
    let l: RField
    let r: RField
}

enum Real: RField, Equatable {
    func eq(_ to: RField) -> Bool {
        guard let to = to as? Real else { return false }
        return self == to
    }
    
    func eval() -> RField {
        switch self {
        case .N(_):
            return self
        case let .Q(q):
            if let n = q.intValue {
                return Real.N(n)
            } else {
                return self
            }
        case let .R(r):
            if abs(r - r.rounded()) < 0.00001 {
                return Real.N(Int(r.rounded()))
            } else {
                return self
            }
        }
    }
    
    case N(Int)
    case Q(Rational<Int>)
    case R(Double)
    
}
