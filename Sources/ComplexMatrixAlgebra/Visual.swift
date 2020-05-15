//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/15.
//

import Foundation

func genLaTex(real:Real) -> String {
    switch real {
    case let .Number(num):
        switch num {
        case let .N(n):
            return n.description
        case let .Q(q):
            return "{\(q.numerator.description) \\over \(q.denominator.description)}"
        case let .R(r):
            return r.description
        }
    case let .Add(l,r):
        return "{\(genLaTex(real: l))} + {\(genLaTex(real: r))}"
    case let .Mul(l, r):
        return "{\(genLaTex(real: l))} \times {\(genLaTex(real: r))}"
    case let .Div(l, r):
        return "\\frac{\(genLaTex(real: l))}{\(genLaTex(real: r))}"
    case let .Subtract(l, r):
        return "{\(genLaTex(real: l))} - {\(genLaTex(real: r))}"
    case let .Negate(x):
        return "-{\(genLaTex(real: x))}"
    case let .Var(v):
        return v
    case let .Inverse(x):
        return "\\left({\(genLaTex(real: x))}\\right)^{-1}"
    }
}
