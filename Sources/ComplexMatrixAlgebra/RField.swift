//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit

protocol RField {
    func eval() -> RField
}
protocol RBinary: RField {
    var l:RField {get}
    var r:RField {get}
}
struct RAdd:RBinary {
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
        return l
    }
    
    let l: RField
    let r: RField
}
struct RMul:RBinary {
    func eval() -> RField {
        
        return self
    }
    
    let l: RField
    let r: RField
}

enum Real: RField {
    func eval() -> RField {
        //TODO: R to Q, Q to N if possible
        return self
    }
    
    case N(Int)
    case Q(Rational<Int>)
    case R(Double)
    
}
