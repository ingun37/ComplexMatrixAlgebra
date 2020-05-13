//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/13.
//

import Foundation

extension Collection {
    func comb2() -> [(Element, Element)] {
        guard let h = first else { return [] }
        let tail = dropFirst()
        return tail.map({($0,h)}) + tail.comb2()
    }
    func seperate<T>() -> ([T],[Element]) {
        let t = compactMap({ $0 as? T})
        let f = filter { !($0 is T) }
        return (t,f)
    }
}

extension Collection where Element:Equatable {
    func without(_ v:Element)-> [Element] {
        return filter { (e) -> Bool in
            e != v
        }
    }
    func without(_ x:Element, _ y:Element)-> [Element] {
        return without(x).without(y)
    }
}

struct Dimension:Hashable {
    let rows:Int
    let cols:Int
    init(_ rows:Int, _ cols:Int) {
        self.rows = rows
        self.cols = cols
    }
}

extension Matrix {
    var rowLen:Int {
        return elems.count
    }
    var colLen:Int {
        return elems.reduce(0) { (x, fx) in x < fx.count ? fx.count : x }
    }
    var dim:(Int, Int) {
        return (rowLen, colLen)
    }
    var dimen:Dimension {
        return Dimension(rowLen, colLen)
    }
    func row(_ i:Int) -> [CField] {
        return elems[i]
    }
    func col(_ i:Int) -> [CField] {
        return elems.map { (row) in row[i] }
    }
    var rows:[[CField]] {
        return elems
    }
    var cols:[[CField]] {
        return (0..<colLen).map { (coli) in col(coli) }
    }
}
