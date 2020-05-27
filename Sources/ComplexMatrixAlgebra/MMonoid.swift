//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/24.
//

import Foundation
indirect enum MMonoidOperators<A:MMonoid>:Operator {
    case Mul(A.MUL)
    func eval() -> A {
        switch self {
        case let .Mul(_b):
            let b = _b
            return b.caseMultiplicationWithId() ?? b.caseBothBasis() ?? b.caseAssociative() ?? b.l * b.r
        }
    }
}

protocol MMonoidBasis:Basis {
    static func * (l:Self, r:Self)->Self
    static var Id:Self {get}
}
protocol MMonoid:Algebra where B:MMonoidBasis {
    associatedtype MUL:AssociativeMultiplication where MUL.A == Self
    typealias MMonO = MMonoidOperators<Self>
    init(mmonoidOp:MMonO)
    var mmonoidOp: MMonO? { get }
}
extension MMonoid {
    static var Id:Self {
        return .init(element: .Basis(.Id))
    }
    static func * (l:Self, r:Self)->Self {
        return .init(mmonoidOp: .Mul(.init(l: l, r: r)))
    }
}
