//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation

protocol GroupBinary {
    associatedtype Alg
    var l: Alg { get }
    var r: Alg { get }
}
extension GroupBinary {
    static func flatTerms(m:Alg) -> [Alg] {
        if let m = m as? Self {
            return flatTerms(m: m.l) + flatTerms(m: m.r)
        } else {
            return [m]
        }
        return []
    }
}
