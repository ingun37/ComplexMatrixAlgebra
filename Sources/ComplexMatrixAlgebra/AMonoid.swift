//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/27.
//

import Foundation

indirect enum AMonoidOperators<A:AMonoid>:Operator {
    case Add(A.ADD)
    func eval() -> A {
        switch self {
        case let .Add(b):
            let l = b.l.eval()
            let r = b.r.eval()
            
            return Self.evalAdd(evaledL: l, evaledR: r)
        }
    }
    static func evalAdd(evaledL:A, evaledR:A) -> A {
        let l = evaledL
        let r = evaledR
        if l == .Zero { return r }
        if r == .Zero { return l }
        
        if case let .Basis(lb) = l.element {
            if case let .Basis(rb) = r.element {
                return A(element: .Basis(lb + rb))
            }
        }
        
        if case let .Add(lm) = l.amonoidOp {
            //(xy)r = x(yr)
            let alter = (lm.r + r)
            let aeval = alter.eval()
            if alter != aeval {
                return (lm.l + aeval).eval()
            }
        }
        
        if case let .Add(rm) = r.amonoidOp {
            //l(xy) = (lx)y
            let alter = (l + rm.l)
            let aeval = alter.eval()
            if alter != aeval {
                return (aeval + rm.r).eval()
            }
        }
        
        return l + r
    }
}

protocol AMonoidBasis:Basis {
    static func + (l:Self, r:Self)->Self
    static var Zero:Self {get}
}
protocol AMonoid:Algebra where B:AMonoidBasis {
    associatedtype ADD:AssociativeBinary where ADD.A == Self
    typealias AMonO = AMonoidOperators<Self>
    init(amonoidOp:AMonO)
    var amonoidOp: AMonO? { get }
}
extension AMonoid {
    static var Zero:Self {
        return .init(element: .Basis(.Zero))
    }
    static func + (l:Self, r:Self)->Self {
        return .init(amonoidOp: .Add(.init(l: l, r: r)))
    }
}
