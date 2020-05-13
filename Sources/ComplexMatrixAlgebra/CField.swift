//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation

struct CEq: Equatable {
    static func == (lhs: CEq, rhs: CEq) -> Bool {
        return lhs.c.eq(rhs.c)
    }
    
    let c: CField
}

protocol CField {
    func eval() -> CField
    func eq(_ to:CField) -> Bool
}
extension CField {
    var equatable:CEq {
        return CEq(c: self)
    }
    static var zero:CField {
        return Complex(i: Real.zero, real: Real.zero)
    }
}
struct Complex:CField {
    func eval() -> CField {
        let i = self.i.eval()
        let r = self.real.eval()
        return Complex(i: i, real: r)
    }
    
    func eq(_ to: CField) -> Bool {
        guard let to = to as? Complex else { return false }
        return i.eq(to.i) && real.eq(to.real)
    }
    
    let i: RField
    let real: RField
}
protocol CBinary:CField {
    var l:CField { get }
    var r:CField { get }
}
struct CAdd: CBinary {
    func eval() -> CField {
        let l = self.l.eval()
        let r = self.r.eval()
        
        if let l = l as? Complex, let r = r as? Complex {
            let img = RAdd(l: l.i, r: r.i)
            let real = RAdd(l: l.real, r: r.real)
            return Complex(i: img, real: real).eval()
        }
        
        return CAdd(l: l, r: r)
    }
    
    func eq(_ to: CField) -> Bool {
        guard let to = to as? CAdd else { return false }
        return l.eq(to.l) && r.eq(to.r)
    }
    
    let l: CField
    let r: CField
}
struct CMul: CBinary {
    func eval() -> CField {
        let l = self.l.eval()
        let r = self.r.eval()
        
        if let l = l as? Complex, let r = r as? Complex {
            let img = RAdd(l: RMul(l: l.i, r: r.real), r: RMul(l: l.real, r: r.i))
            let real = RSubtract(l: RMul(l: l.real, r: r.real), r: RMul(l: l.i, r: r.i))
            return Complex(i: img, real: real).eval()
        }
        
        return CMul(l: l, r: r)
    }
    
    func eq(_ to: CField) -> Bool {
        guard let to = to as? CMul else { return false }
        return l.eq(to.l) && r.eq(to.r)
    }
    
    let l: CField
    let r: CField
}
