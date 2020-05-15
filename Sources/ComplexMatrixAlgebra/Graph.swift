//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/15.
//

import Foundation
import SwiftGraph

func edgeMerge<T:Codable&Equatable>(objs:[T], merger:(T,T)->T?)->[T]{
    var g = SwiftGraph.UnweightedGraph(vertices: objs)
    for (x,y) in objs.comb2() {
        g.addEdge(from: x, to: y, directed: false)
    }
    
    while let e = g.edgeList().first {
        let x = g.vertexAtIndex(e.u)
        let y = g.vertexAtIndex(e.v)
        g.removeEdge(e)
        if let m = merger(x, y) {
            g.removeVertex(x)
            g.removeVertex(y)
            let vs = g.vertices
            g.addVertex(m)
            for v in vs {
                g.addEdge(from: m, to: v, directed: false)
            }
        }
    }
    return g.vertices
}
