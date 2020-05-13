import XCTest
import Nimble

@testable import ComplexMatrixAlgebra

final class ComplexMatrixAlgebraTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ComplexMatrixAlgebra().text, "Hello, World!")
        expect(1).to(equal(1))
        expect(RAdd(l: Real.N(3), r: Real.N(-3)).eval().equatable).to(equal(Real.N(0).equatable))
        expect(RMul(l: Real.N(2), r: Real.N(4)).eval().equatable).to(equal(Real.N(8).equatable))
        expect(RMul(l: Real.R(2), r: Real.R(0.5)).eval().equatable).to(equal(Real.N(1).equatable))
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
