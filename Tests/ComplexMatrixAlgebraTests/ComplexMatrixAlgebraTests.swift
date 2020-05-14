import XCTest
import Nimble
import struct NumberKit.Rational

@testable import ComplexMatrixAlgebra

final class ComplexMatrixAlgebraTests: XCTestCase {
    func testOutput() {
        print([1,2,3,4].comb2())
        print([1,2,3,4].permutations())
    }
    func testExample() {
        let r1 = 1.real
        let r0 = 0.real
        let r2 = 2.real
        let c1 = 1.complex(i: 0)
        let c0 = 0.complex(i: 0)
        let c2 = 2.complex(i: 0)
        let r_1 = (-1).real
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ComplexMatrixAlgebra().text, "Hello, World!")
        expect(1).to(equal(1))
        expect(Real.Add(RealBinary(l: 3.real, r: (-3).real)).eval()).to(equal(0.real))
        expect(Real.Mul(RealBinary(l: 2.real, r: 4.real)).eval()).to(equal(8.real))
        expect(Real.Mul(RealBinary(l: 2.real, r: 0.5.real)).eval()).to(equal(1.real))
        // 1/2 * 2 = 1
        expect(Real.Mul(RealBinary(l: Rational(1, 2).real, r: 2.real)).eval()).to(equal(1.real))
        // 1 - 2 = -1
        expect(Real.Subtract(RealBinary(l: 1.real, r: 2.real)).eval()).to(equal((-1).real))
        // 2+1i + -1+1i = 1+2i
        expect(Complex.Add(ComplexBinary(l: 2.complex(i: 1), r: (-1).complex(i: 1))).eval()).to(equal(1.complex(i: 2)))
        //2+i * -1+i = -3+i
        expect(Complex.Mul(ComplexBinary(l: 2.complex(i: 1), r: (-1).complex(i: 1))).eval()).to(equal((-3).complex(i: 1)))


        let m22_1 = Matrix.a(Elements(e: [[c1, c0],[c0, c1]]))
        let m22_2 = Matrix.a(Elements(e: [[c2, c0],[c0, c2]]))
        expect(Matrix.Scale(c2, m22_1).eval()).to(equal(m22_2))
        expect(Matrix.Add(MatrixBinary(l: m22_1, r: m22_1)).eval()).to(equal(m22_2))

        let m1 = [[(1,0),(0,-1)],
                  [(1,1),(4,-1)]].matrix
        let m2 = [[(0,1),(1,-1)],
                  [(2,-3),(4,0)]].matrix
        
        let expectedMul = [[(-3,-1),(1,-5)],
                           [(4,-13),(18,-4)]].matrix
        let expectedAdd = [[(1,1),(1,-2)],
                           [(3,-2),(8,-1)]].matrix
        
        expect(Matrix.Mul(MatrixBinary(l: m1, r: m2)).eval()).to(equal(expectedMul))
        expect(Matrix.Add(MatrixBinary(l: m1, r: m2)).eval()).to(equal(expectedAdd))
        
    }
    static var allTests = [
        ("testExample", testExample),
    ]
}

extension Collection where Element == (Int, Int){
    var complexes: [Complex] {
        return map { (x,y) in x.complex(i: y) }
    }
}
extension Collection where Element:Collection, Element.Element == (Int, Int){
    var matrix:Matrix {
        return Matrix.a(Elements(e: map({$0.complexes})))
    }
}
extension Int {
    var real: Real {
        return Real.Number(RealNumber.N(self))
    }
    func complex(i:Int) -> Complex {
        return Complex.Number(ComplexNumber(i: i.real, real: real))
    }
}
extension Double {
    var real: Real {
        return Real.Number(RealNumber.R(self))
    }
}
extension Rational where T == Int {
    var real: Real {
        return Real.Number(.Q(self))
    }
}
