//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation


protocol CField {
    func eval() -> CField
    func eq(_ to:CField) -> Bool
}
struct Complex:CField {
    func eval() -> CField {
        let i = self.i.eval()
        let r = self.r.eval()
        return Complex(i: i, r: r)
    }
    
    func eq(_ to: CField) -> Bool {
        guard let to = to as? Complex else { return false }
        return i.eq(to.i) && r.eq(to.r)
    }
    
    let i: RField
    let r: RField
}
protocol CBinary:CField {
    var l:CField { get }
    var r:CField { get }
}
struct CAdd: CBinary {
    func eval() -> CField {
        let l = self.l.eval()
        let r = self.r.eval()
        
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
        
        return CMul(l: l, r: r)
    }
    
    func eq(_ to: CField) -> Bool {
        guard let to = to as? CMul else { return false }
        return l.eq(to.l) && r.eq(to.r)
    }
    
    let l: CField
    let r: CField
}
