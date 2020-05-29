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
        case MR(Matrix<Real>)
        case MC(Matrix<Complex>)
    }
    func genLine<T:Field>(_ x:T)-> String {
        return "$$\n" + genLaTex(x) + "=" + genLaTex(x.eval().prettify()) + "\n$$"
    }
    func genLine<F:Field>(_ x:Matrix<F>)-> String {
        let v = x.eval()
        return "$$\n" + genLaTex(x) + "=" + genLaTex(x.eval()) + "\n$$"
    }
    func testOutput() {
        
        let x = "x".rvar
        let y = "y".rvar
        let a = "a".rvar
        let b = "b".rvar
        let _x = -x
        let xy = "x".rvar - "y".rvar
        let xyxy = xy * xy
        let i1 = 2.real.f + "x".rvar
        let bbb = 2.real.f + 1.real.f
        let hhh = ComplexBasis(r: 4.real.f, i: "x".rvar).f
        let uc = "x".rvar + 1.real.f
        let cu = 1.real.f + "x".rvar
        let auhs = 3.complex(i: 4).f
        let ggg = (ComplexBasis(r: "a_1".rvar, i: "b_1".rvar)).f
        let hch = (ComplexBasis(r: "a_2".rvar, i: "b_2".rvar)).f
        let z = (ComplexBasis(r: x, i: y)).f
        let ddd = [[x, a],
                   [b, y]].matrix()
        let rm = [[0, 3, -6, 6, 4, -5],
                  [3, -7, 8, -5, 8, 9],
                  [3, -9, 12, -9, 6, 15]].rmatrix()
        let samples:[Sum] = [.R(x*x),.R(x * xy), .R(_x * _x) , .R(xyxy), .R(i1^bbb), .C(hhh/3.complex(i: 4).f), .R((uc^2.real.f) * (cu^2.real.f)), .C(~auhs), .C(ggg*hch), .C(z * *z), .R(.init(fieldOp: .Determinant(ddd))), .MR(.init(.o(.RowReduced(rm))))]
        
        let tex = samples.map { (expression) in
            switch expression {
            case let .C(expression): return genLine(expression)
            case let .R(expression): return genLine(expression)
            case let .MC(exp): return genLine(exp)
            case let .MR(exp): return genLine(exp)
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
        
        
        expect(Real(fieldOp: .Power(base: 2.real.f, exponent: 2.real.f)).eval()).to(equal(4.real.f))
        expect(Real(fieldOp: .Power(base: 2.real.f, exponent: (-2).real.f)).eval()).to(equal(1.on(4).real.f))
        
//        expect(RealBasis.N(2)^2).to(equal(RealBasis.N(4)))
//        expect(RealBasis.N(2)^(-2)).to(equal(RealBasis.Q(1.on(4))))
        
        let uc = "x".rvar + 1.real.f
        let cu = 1.real.f + "x".rvar
        let aoeu = (uc^2.real.f) * (cu^2.real.f)
//        expect(aoeu.eval()).to(equal(cu^(4.real.f)))
        let auhs = 3.complex(i: 4).f
        expect((~auhs).eval()).to(equal(3.on(25).complex(i: (-4).on(25)).f))
        
        let zz = 3.complex(i: 4).f
        expect((zz * *zz).eval()).to(equal(25.complex(i: 0).f))
        
        let m0 = [[(0,0)],].matrix()

        let m1 = [[(1,0),(0,-1)],
                  [(1,1),(4,-1)]].matrix()
        
        expect((m0 + m1).eval()).to(equal(m1))
        
        let m2 = [[(0,1),(1,-1)],
                  [(2,-3),(4,0)]].matrix()

        
        let expectedMul = [[(-3,-1),(1,-5)],
                           [(4,-13),(18,-4)]].matrix()
        let expectedAdd = [[(1,1),(1,-2)],
                           [(3,-2),(8,-1)]].matrix()
        let expectedScaleBy2 = [[(0,2),(2,-2)],
                                [(4,-6),(8,0)]].matrix()
        expect((m1 * m2).eval()).to(equal(expectedMul))
        expect((m1 + m2).eval()).to(equal(expectedAdd))
        expect(((2.complex(i: 0).f * m2)).eval()).to(equal(expectedScaleBy2))
        
        let mxx = [[1, 5, 0],
                   [2, 4,-1],
                   [0,-2, 0]].matrix()
        expect(Complex.init(fieldOp: .Determinant(mxx)).eval()).to(equal((-2).complex(i: 0).f))
        
        
        let myx = [[ 2, 5],
                   [-3,-7]].rmatrix()
        expect(Matrix<Real>.init(.o(.Inverse(myx))).eval()).to(equal([[-7,-5],[3,2]].rmatrix()))

    }
    static var allTests = [
        ("testExample", testExample),
    ]
}

extension Collection where Element == (Int, Int){
    var complexes:List<Complex> {
        return map { (x,y) in x.complex(i: y) }.decompose()!.fmap { (x) in x.f }
    }
}
extension Collection where Element == List<Complex>{
    func matrix()-> Matrix<Complex> {
        let e = decompose()!
        return .init(element: .Basis(.Matrix(.init(e: e))))
//        return Matrix(op: Ring.Number(MatrixNumber<N, Complex>(e: e)))
    }
}
extension Collection where Element: Collection, Element.Element == Real {
    func mat()->Mat<Real> {
        let aaa = map({$0.decompose()!}).decompose()!
        return .init(e: aaa)
    }
    func matrix()->Matrix<Real> {
        let aaa = map({$0.decompose()!}).decompose()!
        return .init(element: .Basis(.Matrix(.init(e: aaa))))
    }
}
extension Collection where Element: Collection, Element.Element == (Int,Int) {
    func matrix()->Matrix<Complex> {
        return map({$0.complexes}).matrix()
    }
}

extension Collection where Element: Collection, Element.Element == Int {
    func matrix()->Matrix<Complex> {
        let rows = map { (row) in
            row.map { (i) in
                i.complex(i: 0).f
            }.decompose()!
        }.decompose()!
        return Matrix(element: .Basis(.Matrix(.init(e: rows))))
    }
    func rmatrix()->Matrix<Real> {
        let rows = map { (row) in
            row.map { (i) in
                i.real.f
            }.decompose()!
        }.decompose()!
        return Matrix(element: .Basis(.Matrix(.init(e: rows))))
    }
}
