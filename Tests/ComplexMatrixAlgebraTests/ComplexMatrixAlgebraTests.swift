import XCTest
import Nimble
import struct NumberKit.Rational

@testable import ComplexMatrixAlgebra

final class ComplexMatrixAlgebraTests: XCTestCase {
    func testExample() {
        let r1 = Real.N(1)
        let r0 = Real.N(0)
        let r2 = Real.N(2)
        let c1 = Complex(i: r0, real: r1)
        let c0 = Complex(i: r0, real: r0)
        let c2 = Complex(i: r0, real: r2)
        let m22_1 = Matrix(elems: [[c1, c0],[c0, c1]])
        let m22_2 = Matrix(elems: [[c2, c0],[c0, c2]])
        let r_1 = Real.N(-1)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ComplexMatrixAlgebra().text, "Hello, World!")
        expect(1).to(equal(1))
        expect(RAdd(l: Real.N(3), r: Real.N(-3)).eval().equatable).to(equal(Real.N(0).equatable))
        expect(RMul(l: Real.N(2), r: Real.N(4)).eval().equatable).to(equal(Real.N(8).equatable))
        expect(RMul(l: Real.R(2), r: Real.R(0.5)).eval().equatable).to(equal(Real.N(1).equatable))
        expect(RMul(l: Real.Q(Rational(1, 2)), r: r2).eval().equatable).to(equal(r1.equatable))
        expect(RSubtract(l: r1, r: r2).eval().equatable).to(equal(r_1.equatable))
        expect(CAdd(l: Complex(i: r1, real: r2), r: Complex(i: r1, real: r_1)).eval().equatable).to(equal(Complex(i: r2, real: r1).equatable))
        expect(CMul(l: Complex(i: r1, real: r2), r: Complex(i: r1, real: r_1)).eval().equatable).to(equal(Complex(i: r1, real: Real.N(-3)).equatable))
        
        expect(MScale(k: c2, m: m22_1).eval().equatable).to(equal(Matrix(elems: [[c2, c0],[c0, c2]]).eval().equatable))
        expect(MAdd(l: m22_1, r: m22_1).eval().equatable).to(equal(m22_2.equatable))
        
        let m1 = [[(1,0),(0,-1)],
                  [(1,1),(4,-1)]].matrix
        let m2 = [[(0,1),(1,-1)],
                  [(2,-3),(4,0)]].matrix
        let m3 = [[(-3,-1),(1,-5)],
                  [(4,-13),(18,-4)]].matrix
        expect(MMul(l: m1, r: m2).eval().equatable).to(equal(m3.equatable))
        
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

extension Collection where Element == (Int, Int){
    var complexes: [Complex] {
        return map { (x,y) in Complex(i: Real.N(y), real: Real.N(x)) }
    }
}
extension Collection where Element:Collection, Element.Element == (Int, Int){
    var matrix:Matrix {
        return Matrix(elems: map({$0.complexes}))
    }
}
