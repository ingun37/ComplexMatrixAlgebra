//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation

public struct ComplexBasis: FieldBasis {
    public static func whole(n: Int) -> ComplexBasis {
        return .init(r: .init(element: .Basis(.N(n))), i: .Zero)
    }
    
    public static prefix func * (lhs: ComplexBasis) throws -> ComplexBasis {
        return try ComplexBasis(r: lhs.r, i: -lhs.i).eval()
    }
    
    static func / (lhs: ComplexBasis, rhs: ComplexBasis) throws -> ComplexBasis {
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
        return try ComplexBasis(r: r, i: i).eval()
    }
    
    
    public static prefix func ~ (lhs: ComplexBasis) throws -> ComplexBasis {
        return try (*lhs / (lhs * *lhs)).eval()
    }
    
    public static prefix func - (lhs: ComplexBasis) -> ComplexBasis {
        return ComplexBasis(r: -lhs.r, i: -lhs.i)
    }
    
    static func - (lhs: ComplexBasis, rhs: ComplexBasis) throws -> ComplexBasis {
        return try ComplexBasis(r: lhs.r - rhs.r, i: lhs.i - rhs.i).eval()
    }
    
    public static func + (lhs: ComplexBasis, rhs: ComplexBasis) throws -> ComplexBasis {
        return try ComplexBasis(r: lhs.r + rhs.r, i: lhs.i + rhs.i).eval()
    }
    
    let r:Real
    let i:Real

    public static var Zero: ComplexBasis {
        return ComplexBasis(r: Real.Zero, i: Real.Zero)
    }
    
    public static var Id: ComplexBasis {
        return ComplexBasis(r: Real.Id, i: Real.Zero)
    }
    public static var _Id: ComplexBasis {
        return ComplexBasis(r: Real._Id, i: Real.Zero)
    }
    func eval() throws -> ComplexBasis {
        try ComplexBasis(r: r.eval(), i: i.eval())
    }
    
    public static func * (lhs: ComplexBasis, rhs: ComplexBasis) throws -> ComplexBasis {
        let img = (lhs.r * rhs.i) + (lhs.i * rhs.r)
        let real = (lhs.r * rhs.r) - (lhs.i * rhs.i)
        return try ComplexBasis(r: real, i: img).eval()
    }
    
}
public struct ComplexMultiplication:CommutativeMultiplication {
    public let l: Complex
    public let r: Complex
    public typealias A = Complex
    public init(l ll:Complex, r rr:Complex) {
        l = ll
        r = rr
    }
}
public struct ComplexAddition:CommutativeAddition {
    public let l: Complex
    public let r: Complex
    public typealias A = Complex
    public init(l ll:Complex, r rr:Complex) {
        l = ll
        r = rr
    }
}
public struct Complex:Field {
    public static var cache:Dictionary<Int, Complex>? = .init()
    
    public typealias ADD = ComplexAddition
    public typealias MUL = ComplexMultiplication
    public init(_ c: Construction<Complex>) {
        self.c = c
    }
    
    public let c: Construction<Complex>
    
    public var fieldOp: FieldOperators<Complex>? {
        switch c {
        case let .o(f): return f
        default: return nil
        }
    }
    
    public typealias O = FieldOperators<Complex>
    
    
    public init(fieldOp: FieldOperators<Complex>) {
        c = .o(fieldOp)
    }
    public typealias B = ComplexBasis

    
    
    
}
//typealias Complex = Field<ComplexNumber>
