struct ComplexMatrixAlgebra {
    var text = "Hello, World!"
}

protocol MAlg {}
struct MScale: MAlg {
    let k: CField
    let m:MAlg
}
struct Matrix:MAlg {
    let elems: [[CField]]
}
protocol MBinary:MAlg {
    var l:MAlg { get }
    var r:MAlg { get }
}
struct MAdd:MBinary {
    let l: MAlg
    let r: MAlg
}
struct MMul:MBinary {
    let l: MAlg
    let r: MAlg
}
