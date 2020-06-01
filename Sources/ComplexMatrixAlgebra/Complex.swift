//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation

struct ComplexBasis: FieldBasis {
    static func whole(n: Int) -> ComplexBasis {
        return .init(r: .init(element: .Basis(.N(n))), i: .Zero)
    }
    
    static prefix func * (lhs: ComplexBasis) -> ComplexBasis {
        return ComplexBasis(r: lhs.r, i: -lhs.i).eval()
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
struct ComplexMultiplication:CommutativeMultiplication {
    let l: Complex
    let r: Complex
    typealias A = Complex
}
struct ComplexAddition:CommutativeAddition {
    let l: Complex
    let r: Complex
    typealias A = Complex
}
public struct Complex:Field {
    static var cache:Dictionary<Int, Complex>? = .init()
    
    typealias ADD = ComplexAddition
    typealias MUL = ComplexMultiplication
    init(_ c: Construction<Complex>) {
        self.c = c
    }
    
    let c: Construction<Complex>
    
    var fieldOp: FieldOperators<Complex>? {
        switch c {
        case let .o(f): return f
        default: return nil
        }
    }
    
    typealias O = FieldOperators<Complex>
    
    
    init(fieldOp: FieldOperators<Complex>) {
        c = .o(fieldOp)
    }
    typealias B = ComplexBasis

    
    
    
}
//typealias Complex = Field<ComplexNumber>
