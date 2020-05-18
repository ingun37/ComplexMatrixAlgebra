//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/18.
//

import Foundation


protocol AbelianAddGroupSet:Underlying {
    static var zero: Self {get}
    static func + (lhs: Self, rhs: Self) -> Self
    /**
     abelian group add inverse
     */
    static func - (lhs: Self, rhs: Self) -> Self
}
//enum AbelianAddOperators<F,Num> {
//    case Number(Num)
//    case Add(F,F)
//    case Subtract(F, F)
//    case Negate(F)
//    case Var(String)
//    case Inverse(F)
//}
//protocol AbelianAddOpSum:OperatorSum where A:AbelianAdd, Num:AbelianAddGroupSet {
//    typealias O = AbelianAddOperators<A,Num>
//    init(abelianAddOp:O)
//    var abelianAddOp:O {get}
//}
//protocol AbelianAdd:Algebra where OpSum: AbelianAddOpSum {
//    
//}
//struct MatrixNumber:AbelianAddGroupSet {
//    static var zero: MatrixNumber
//    
//    func eval() -> MatrixNumber {
//        <#code#>
//    }
//    
//    
//}
//struct MatrixOpSum:AbelianAddOpSum {
//    let abelianAddOp: O
//    typealias A = Matrix
//    
//    typealias Num = MatrixNumber
//    
//    
//}
//struct Matrix:AbelianAdd {
//    typealias OpSum = MatrixOpSum
//    
//    
//}
//
