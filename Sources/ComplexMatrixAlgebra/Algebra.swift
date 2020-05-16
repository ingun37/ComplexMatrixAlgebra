//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation
import NumberKit

//TODO: Change once accepted: https://forums.swift.org/t/accepted-se-0280-enum-cases-as-protocol-witnesses/34850
protocol Algebra: Equatable {
    func eval() -> Self
    func same(_ to:Self)-> Bool
}

protocol AbelianGroup:Algebra {
    associatedtype BinaryOp:AbelianGroupBinary where BinaryOp.A == Self //Add or Mul?
    var asBinary: BinaryOp? { get }
}
protocol AbelianGroupBinary {
    associatedtype A:AbelianGroup where A.BinaryOp == Self
    var l: A { get }
    var r: A { get }
    static var id:A {get}
}
struct TempCodable<T:AbelianGroup>:Codable&Equatable {
    func encode(to encoder: Encoder) throws { }
    init(from decoder: Decoder) throws { self.x = T.BinaryOp.id }
    init(_ x:T) {
        self.x = x
    }
    let x:T
}
extension AbelianGroupBinary {
    func flatten() -> (A,[A]) {
        let (lh,lt) = l.asBinary?.flatten() ?? (l,[])
        let (rh,rt) = r.asBinary?.flatten() ?? (r,[])
        return (lh, lt + [rh] + rt)
    }
    
}


func commuteSame<C:Collection, T:Algebra>(_ xs:C, _ ys:C) -> Bool where C.Element == T, C.Index == Int{
    guard xs.count == ys.count else { return false }
    let len = xs.count
    if len == 0 { return true }
    let aa = (0..<len).flatMap({i in (0..<len).map({(i,$0)})})
    if let match = aa.first(where: { xs[$0].same(ys[$1]) }) {
        return commuteSame(xs.without(at:match.0), ys.without(at: match.1))
    } else {
        return false
    }
    
}
