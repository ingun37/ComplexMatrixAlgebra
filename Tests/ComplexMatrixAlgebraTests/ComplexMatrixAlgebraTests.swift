import XCTest
import Nimble
import Cocoa
import struct NumberKit.Rational

@testable import ComplexMatrixAlgebra

final class ComplexMatrixAlgebraTests: XCTestCase {
    func testUtil() {
        print([1,2,3,4].comb2())
        print(Array((-3)..<0))
    }
    enum Sum {
        case C(Complex)
        case R(Real)
    }
    func genLine<T>(_ x:Field<T>)-> String {
        return "$$\n" + genLaTex(x) + "=" + genLaTex(x.eval()) + "\n$$"
    }
    func testOutput() {
        
        let x = "x".rvar
        let y = "y".rvar
        let _x = -x
        let xy = "x".rvar - "y".rvar
        let xyxy = xy * xy
        let i1 = 2.real.f + "x".rvar
        let bbb = 2.real.f + 1.real.f
        let hhh = Complex.Number(ComplexNumber(r: 4.real.f, i: "x".rvar))
        let uc = "x".rvar + 1.real.f
        let cu = 1.real.f + "x".rvar
        let auhs = 3.complex(i: 4).f
        let ggg = Complex.Number(ComplexNumber(r: "a_1".rvar, i: "b_1".rvar))
        let hch = Complex.Number(ComplexNumber(r: "a_2".rvar, i: "b_2".rvar))
        let z = Complex.Number(ComplexNumber(r: x, i: y))
        let samples:[Sum] = [.R(x*x),.R(x * xy), .R(_x * _x) , .R(xyxy), .R(i1^bbb), .C(hhh/3.complex(i: 4).f), .R((uc^2.real.f) * (cu^2.real.f)),
                             .C(~auhs), .C(ggg*hch), .C(z * *z)]
        
        let tex = samples.map { (expression) in
            switch expression {
            case let .C(expression): return genLine(expression)
            case let .R(expression): return genLine(expression)
            }
            
        }.joined(separator: "\n\n")
        let template = """
            <script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
            <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
            
            aoeuaoeu
            
        """
        try? template.replacingOccurrences(of: "aoeuaoeu", with: tex).write(toFile: "preview.html", atomically: true, encoding: String.Encoding.utf8)
        NSWorkspace.shared.open(URL(fileURLWithPath: "preview.html"))
    }
    func testExample() {
        let r1 = 1.real.f
        let r0 = 0.real.f
        let r2 = 2.real.f
        
        let r_1 = (-1).real
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ComplexMatrixAlgebra().text, "Hello, World!")
        
        expect((3.real.f + -3.real.f).eval()).to(equal(0.real.f))
        expect((2.real.f * 4.real.f).eval()).to(equal(8.real.f))
        expect((2.real.f * 0.5.real.f).eval()).to(equal(1.real.f))
        // 1/2 * 2 = 1
        expect((Rational(1,2).real.f * 2.real.f).eval()).to(equal(1.real.f))
        // 1 - 2 = -1
        expect((1.real.f - 2.real.f).eval()).to(equal((-1).real.f))
        expect(("x".rvar + 0.real.f).eval()).to(equal("x".rvar))
            
        /**
         Terms are distributed otherwise compiling won't end.
         */
        do {
            let x = 1.real.f + "x".rvar
            expect((x + 1.real.f).eval()).to(equal(2.real.f + "x".rvar))
        }
        
        expect((4.real.f / (-2).real.f).eval()).to(equal((-2).real.f))
            
        do {
            let x = (-3.real.f * "x".rvar)
            let y = (x * (-4).real.f)
            expect((y * "y".rvar).eval()).to(equal(12.real.f * "x".rvar * "y".rvar))
        }
        
        expect((4.complex(i: 3).f/3.complex(i: 4).f).eval()).to(equal(24.on(25).complex(i: (-7).on(25)).f))
        expect(
            (~(3.complex(i: 4).f)).eval()
        ).to(equal(
            3.on(25).complex(i: -4.on(25)).f.eval()
        ))
        
        expect((2.complex(i: 3).f * 3.complex(i: 4).f).eval()).to(equal((-6).complex(i: 17).f))
        
        expect(RealNumber.N(2)^2).to(equal(RealNumber.N(4)))
        expect(RealNumber.N(2)^(-2)).to(equal(RealNumber.Q(1.on(4))))
        
        let uc = "x".rvar + 1.real.f
        let cu = 1.real.f + "x".rvar
        let aoeu = (uc^2.real.f) * (cu^2.real.f)
        expect(aoeu.eval()).to(equal(uc^(4.real.f)))
        let auhs = 3.complex(i: 4).f
        expect((~auhs).eval()).to(equal(3.on(25).complex(i: (-4).on(25)).f))
        
        let zz = 3.complex(i: 4).f
        expect((zz * *zz).eval()).to(equal(25.complex(i: 0).f))
//
//        let m22_1 = Matrix.a(Elements(e: [[c1, c0],[c0, c1]]))
//        let m22_2 = Matrix.a(Elements(e: [[c2, c0],[c0, c2]]))
//        expect(Matrix.Scale(c2, m22_1).eval()).to(equal(m22_2))
//        expect(Matrix.Add(MatrixBinary(l: m22_1, r: m22_1)).eval()).to(equal(m22_2))
//
//        let m1 = [[(1,0),(0,-1)],
//                  [(1,1),(4,-1)]].matrix
//        let m2 = [[(0,1),(1,-1)],
//                  [(2,-3),(4,0)]].matrix
//
//        let expectedMul = [[(-3,-1),(1,-5)],
//                           [(4,-13),(18,-4)]].matrix
//        let expectedAdd = [[(1,1),(1,-2)],
//                           [(3,-2),(8,-1)]].matrix
//
//        expect(Matrix.Mul(MatrixBinary(l: m1, r: m2)).eval()).to(equal(expectedMul))
//        expect(Matrix.Add(MatrixBinary(l: m1, r: m2)).eval()).to(equal(expectedAdd))
        
    }
    static var allTests = [
        ("testExample", testExample),
    ]
}

extension Collection where Element == (Int, Int){
//    var complexes: [Complex] {
//        return map { (x,y) in x.complex(i: y) }
//    }
}
extension Collection where Element:Collection, Element.Element == (Int, Int){
//    var matrix:Matrix {
//        return Matrix.a(Elements(e: map({$0.complexes})))
//    }
}
