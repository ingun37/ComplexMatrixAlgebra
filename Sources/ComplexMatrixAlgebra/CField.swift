//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation


protocol CField {}
struct Complex:CField {
    let i: RField
    let r: RField
}
protocol CBinary {
    var l:CField { get }
    var r:CField { get }
}
struct CAdd: CBinary {
    let l: CField
    let r: CField
}
struct CMul: CBinary {
    let l: CField
    let r: CField
}
