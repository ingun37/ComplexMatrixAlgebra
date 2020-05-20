//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation

struct ComplexBasis: FieldBasis {
    
    static prefix func * (lhs: ComplexBasis) -> ComplexBasis {
        return ComplexBasis(r: lhs.r, i: -lhs.i).eval()
    }
    
    static func ^ (lhs: ComplexBasis, rhs: ComplexBasis) -> ComplexBasis? {
        if rhs.i == .Zero {
            if case let .Number(.N(intExp)) = rhs.r.op.ringOp {
                return lhs^intExp
            }
        }
        return nil
    }
    
    
    static func / (lhs: ComplexBasis, rhs: ComplexBasis) -> ComplexBasis {
        //compiling never ends
        let a1 = lhs.r
        let b1 = lhs.i
        let a2 = rhs.r
        let b2 = rhs.i
        let a1a2 = a1 * a2
        let b1b2 = b1 * b2
        let a22 = a2 * a2
        let b22 = b2 * b2
        let a22_b22 = a22 + b22
        let b1a2 = b1 * a2
        let a1b2 = a1 * b2
        let r = (a1a2 + b1b2) / a22_b22
        let i = (b1a2 - a1b2) / a22_b22
        return ComplexBasis(r: r, i: i).eval()
    }
    
    
    static prefix func ~ (lhs: ComplexBasis) -> ComplexBasis {
        return (*lhs / (lhs * *lhs)).eval()
    }
    
    static prefix func - (lhs: ComplexBasis) -> ComplexBasis {
        return ComplexBasis(r: -lhs.r, i: -lhs.i).eval()
    }
    
    static func - (lhs: ComplexBasis, rhs: ComplexBasis) -> ComplexBasis {
        return ComplexBasis(r: lhs.r - rhs.r, i: lhs.i - rhs.i).eval()
    }
    
    static func + (lhs: ComplexBasis, rhs: ComplexBasis) -> ComplexBasis {
        return ComplexBasis(r: lhs.r + rhs.r, i: lhs.i + rhs.i).eval()
    }
    
    let r:Real
    let i:Real

    static var Zero: ComplexBasis {
        return ComplexBasis(r: Real.Zero, i: Real.Zero)
    }
    
    static var Id: ComplexBasis {
        return ComplexBasis(r: Real.Id, i: Real.Zero)
    }
    
    func eval() -> ComplexBasis {
        ComplexBasis(r: r.eval(), i: i.eval())
    }
    
    static func * (lhs: ComplexBasis, rhs: ComplexBasis) -> ComplexBasis {
        let img = (lhs.r * rhs.i) + (lhs.i * rhs.r)
        let real = (lhs.r * rhs.r) - (lhs.i * rhs.i)
        return ComplexBasis(r: real, i: img).eval()
    }
    
}

struct ComplexOperable:FieldOperable {
    init(fieldOp: FieldOperators<Complex, ComplexBasis>) {
        self.fieldOp = fieldOp
    }
    
    
    init(ringOp: RingO) {
        fieldOp = .Ring(ringOp)
    }
    
    var ringOp: RingO? {
        switch fieldOp {
        case let .Ring(r): return r
        default:return nil
        }
    }
    
    let fieldOp: FieldOperators<A,U>
    
    typealias A = Complex
    
    typealias U = ComplexBasis
    
    
}

struct Complex:Field {
    func eval() -> Complex {
        return evalField()
    }
    
    func same(_ to: Complex) -> Bool {
        return sameField(to)
    }
    
    
    let op: ComplexOperable
    
    
}
//typealias Complex = Field<ComplexNumber>
