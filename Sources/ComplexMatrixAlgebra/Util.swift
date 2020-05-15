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
    func seperate(_ criteria:(Element)->Bool) -> ([Element],[Element]) {
        let t = filter(criteria)
        let f = filter { !criteria($0) }
        return (t,f)
    }
    
}

extension Collection where Index == Int {
    func decompose() -> (Element, [Element])? {
        guard let x = first else { return nil }
        return (x, Array(dropFirst()))
    }
    func permutations() -> [[Element]] {
        guard let (head, tail) = decompose() else { return [[]] }
        return tail.permutations().flatMap { between(x: head, $0) }
    }
    func without(at:Int)->[Element] {
        return (0..<count).without(at).map({self[$0]})
    }
}

func between<T>(x: T, _ ys: [T]) -> [[T]] {
    guard let (head, tail) = ys.decompose() else { return [[x]] }
    return [[x] + ys] + between(x:x, tail).map { [head] + $0 }
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

//extension Elements {
//    var rowLen:Int {
//        return e.count
//    }
//    var colLen:Int {
//        return e.reduce(0) { (x, fx) in x < fx.count ? fx.count : x }
//    }
//    var dim:(Int, Int) {
//        return (rowLen, colLen)
//    }
//    var dimen:Dimension {
//        return Dimension(rowLen, colLen)
//    }
//    func row(_ i:Int) -> [Complex] {
//        return e[i]
//    }
//    func col(_ i:Int) -> [Complex] {
//        return e.map { (row) in row[i] }
//    }
//    var rows:[[Complex]] {
//        return e
//    }
//    var cols:[[Complex]] {
//        return (0..<colLen).map { (coli) in col(coli) }
//    }
//}
//extension Real {
//    static var zero:Real {
//        return .Number(.N(0))
//    }
//}
//extension Complex {
//    static var zero:Complex {
//        return .Number(ComplexNumber(i: Real.zero, real: Real.zero))
//    }
//}
