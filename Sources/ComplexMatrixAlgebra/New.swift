//
//  File.swift
//  
//
//  Created by Ingun Jon on 2020/05/18.
//

import Foundation

//protocol OperatorSum {
//    associatedtype A:Algebra
//    associatedtype Num:Underlying
//}
////TODO: Change once accepted: https://forums.swift.org/t/accepted-se-0280-enum-cases-as-protocol-witnesses/34850
//protocol _Algebra {
//    associatedtype O:OperatorSum where O.A == Self
//    func eval() -> Self
//    func same(_ to:Self)-> Bool
//    init(op:O)
//    var op: O {
//        get
//    }
//}
//
//protocol FieldOperatorSum: OperatorSum where A: _Field, Num: FieldSet {
//    var op: FieldOps<A,Num> { get }
//    init(op:FieldOps<A,Num>)
//}
//extension FieldOperatorSum where A.O == Self  {
//    var asField:A {
//        return A(op: self)
//    }
//}
//protocol _Field:_Algebra where O:FieldOperatorSum {
//}
//extension _Field {
//    func sameField(_ to: Self) -> Bool {
//        switch (op.op, to.op.op) {
//        case let (.Add(xl,xr), .Add(yl,yr)):
//            let x = ACAdd(xl, xr)
//            let y = ACAdd(yl, yr)
//            return commuteSame(x.flat().all, y.flat().all)
//        case let (.Mul(xl,xr), .Mul(yl,yr)):
//            let x = ACMul(xl, xr)
//            let y = ACMul(yl, yr)
//            return commuteSame(x.flat().all, y.flat().all)
//        default:
//            return self == to
//        }
//    }
//}
//
//indirect enum FieldOps<F,Num> {
//    case Number(Num)
//    case Add(F,F)
//    case Mul(F,F)
//    case Quotient(F, F)
//    case Subtract(F, F)
//    case Negate(F)
//    case Var(String)
//    case Inverse(F)
//    case Power(base:F, exponent:F)
//    case Conjugate(F)
//}
//extension FieldOps where F:_Field, Num == F.O.Num {
//    var asSum: F.O {
//        return F.O(op: self)
//    }
//}
//struct ACAdd<A:_Field>:ACBinary {
//    static func operation(lhs: A, rhs: A) -> A {
//        return lhs + rhs
//    }
//
//    static func tryCollapse(_ l: A, _ r: A) -> A? {
//        if l == A.O.Num.zero {
//            return r
//        } else if case let (.Number(l), .Number(r)) = (l.op.op,r.op.op) {
//            return A(op:.Number(l + r))
//        } else if (-l).eval().same(r) {
//            return A.zero
//        } else {
//            return nil
//        }
//    }
//
//    static func match(_ a: A) -> ACAdd? {
//        if case let A.OperatorSum.Add(xl,xr) = a.op {
//            return ACAdd(xl,xr)
//        } else {
//            return nil
//        }
//    }
//
//    let l: A
//    let r: A
//    init(_ l:A, _ r:A) {
//        self.l = l
//        self.r = r
//    }
//}
//struct ACMul<A:_Field>:ACBinary {
//    static func operation(lhs: A, rhs: A) -> A {
//        return lhs * rhs
//    }
//
//    typealias A = A
//    static func tryCollapse(_ l: A, _ r: A) -> A? {
//        if case let .Add(x, y) = l.op {
//            let xr = x * r
//            let yr = y * r
//            return (xr + yr).eval()
//        } else if l == A.id {
//            return r
//        } else if l == A.zero {
//            return A.zero
//        } else if case let (.Number(ln), .Number(rn)) = (l.op,r.op) {
//            return A(op: A.OperatorSum.Number(ln * rn)).eval()
//        }
//        switch (l.op,r.op) {
//        case (.Power(base: let lbase, exponent: let lexp), .Power(base: let rbase, exponent: let rexp)):
//            if lbase.same(rbase) {
//                return A(op: A.OperatorSum.Power(base: lbase, exponent: lexp + rexp)).eval()
//            }
//        default:
//            return nil
//        }
//        return nil
//    }
//
//    static func match(_ a: A) -> ACMul? {
//        if case let A.OperatorSum.Mul(xl,xr) = a.op {
//            return FMul(xl, xr)
//        } else {
//            return nil
//        }
//    }
//
//    let l: A
//    let r: A
//    init(_ l:A, _ r:A) {
//        self.l = l
//        self.r = r
//    }
//}
//
