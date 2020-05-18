//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation

struct ComplexNumber: FieldSet {
    static prefix func * (lhs: ComplexNumber) -> ComplexNumber {
        return ComplexNumber(r: lhs.r, i: -lhs.i).eval()
    }
    
    static func ^ (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber? {
        if rhs.i == .zero {
            if case let .Number(.N(intExp)) = rhs.r.op.op {
                return lhs^intExp
            }
        }
        return nil
    }
    
    
    static func / (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
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
        return ComplexNumber(r: r, i: i).eval()
    }
    
    
    static prefix func ~ (lhs: ComplexNumber) -> ComplexNumber {
        return (*lhs / (lhs * *lhs)).eval()
    }
    
    static prefix func - (lhs: ComplexNumber) -> ComplexNumber {
        return ComplexNumber(r: -lhs.r, i: -lhs.i).eval()
    }
    
    static func - (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
        return ComplexNumber(r: lhs.r - rhs.r, i: lhs.i - rhs.i).eval()
    }
    
    static func + (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
        return ComplexNumber(r: lhs.r + rhs.r, i: lhs.i + rhs.i).eval()
    }
    
    let r:Real
    let i:Real

    static var zero: ComplexNumber {
        return ComplexNumber(r: Real.zero, i: Real.zero)
    }
    
    static var id: ComplexNumber {
        return ComplexNumber(r: Real.id, i: Real.zero)
    }
    
    func eval() -> ComplexNumber {
        ComplexNumber(r: r.eval(), i: i.eval())
    }
    
    static func * (lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
        let img = (lhs.r * rhs.i) + (lhs.i * rhs.r)
        let real = (lhs.r * rhs.r) - (lhs.i * rhs.i)
        return ComplexNumber(r: real, i: img).eval()
    }
    
}

struct ComplexOperatorSum:FieldOpSum {
    let op: O
    
    typealias A = Complex
    
    typealias Num = ComplexNumber
    
    
}

struct Complex:Field {
    
    let op: ComplexOperatorSum
    
    
}
//typealias Complex = Field<ComplexNumber>
