//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/15.
//

import Foundation
import SwiftGraph

enum CodErr:Error {
    case what
}
fileprivate struct Cod<T>:Codable&Equatable {
    static func == (lhs: Cod<T>, rhs: Cod<T>) -> Bool { return true }
    func encode(to encoder: Encoder) throws { }
    init(from decoder: Decoder) throws { throw CodErr.what }
    init(_ x:T) { self.x = x }
    let x:T
    
}
func edgeMerge<T>(_objs:List<T>, merger:(T,T)->T?)->List<T>{
    let objs = _objs.fmap({Cod($0)})
    var pivot = 0
    var g = SwiftGraph.UnweightedGraph(vertices: [objs.head]+objs.tail)
    for (x,y) in (0..<objs.all.count).comb2() {
        g.addEdge(fromIndex: x, toIndex: y, directed: false)
    }
    
    while let e = g.edgeList().first {
        let x = g.vertexAtIndex(e.u)
        let y = g.vertexAtIndex(e.v)
        g.removeEdge(e)
        if let m = merger(x.x, y.x) {
            g.removeVertexAtIndex(max(e.u, e.v))
            g.removeVertexAtIndex(min(e.u, e.v))
            pivot = g.addVertex(Cod(m))
            
            for i in 0..<g.vertexCount {
                if i != pivot {
                    g.addEdge(fromIndex: pivot, toIndex: i, directed: false)
                }
            }
        }
    }
    
    return List(g.vertices[pivot].x, g.vertices.without(at: pivot).map({$0.x}))
}

func associativeMerge<T>(_objs:List<T>, merger:(T,T)->T?)->List<T>{
    let objs = _objs.fmap({Cod($0)})
    var pivot = 0
    var g = SwiftGraph.UnweightedGraph(vertices: [objs.head]+objs.tail)
    for (x,y) in (1..<objs.all.count).map({($0-1,$0)}) {
        g.addEdge(fromIndex: x, toIndex: y, directed: true)
    }
    
    while let e = g.edgeList().first {
        let x = g.vertexAtIndex(e.u)
        let y = g.vertexAtIndex(e.v)
        g.removeEdge(e)
        if let m = merger(x.x, y.x) {
            pivot = g.addVertex(Cod(m))
            if let a = g.verticesTo(e.u).first {
                g.addEdge(fromIndex: a, toIndex: pivot, directed: true)
            }
            if let d = g.verticesFrom(e.v).first {
                g.addEdge(fromIndex: pivot, toIndex: d, directed: true)
            }
            g.removeVertexAtIndex(max(e.u, e.v))
            g.removeVertexAtIndex(min(e.u, e.v))
            pivot = pivot - 2
        }
    }
    
    return List(g.vertices[pivot].x, g.vertices.without(at: pivot).map({$0.x}))
}
extension UnweightedGraph {
    func verticesTo(_ idx:Int)-> [Int] {
        return edgesForIndex(idx).filter { (edge) -> Bool in
            edge.v == idx
        }.map { (edge) in
            edge.u
        }
    }
    func verticesFrom(_ idx:Int)-> [Int] {
        return edgesForIndex(idx).filter { (edge) -> Bool in
            edge.u == idx
        }.map { (edge) in
            edge.v
        }
    }
}
