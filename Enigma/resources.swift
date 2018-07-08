//
//  resources.swift
//  Enigma
//
//  Created by LEO Yoon-Tsaw on 18/4/15.
//  Copyright (c) 2017 Yoon-Tsaw Leo. All rights reserved.
//
private func parse(left: String, right: String) -> ([Character], [Character])? {
    let left = Array(left), right = Array(right)
    guard left.sorted() == right.sorted() && Set(left).count == left.count else {
        return nil
    }
    return (left, right)
}

private func parseReflector(left: String, right: String) -> ([Character], [Character])? {
    let left = Array(left), right = Array(right)
    guard left.count == right.count && Set(left).count == left.count && Set(right).count == right.count else {
        return nil
    }
    return (left, right)
}

let base = 9, seperator: Character = "9"
public let rotors = ([(parse(left: "3194820576", right: "7325091864")!, 1),
    (parse(left: "6234098751", right: "5426801973")!, 2),
    (parse(left: "6735120894", right: "0651924783")!, 3),
    (parse(left: "2816043795", right: "6890751324")!, 5),
    (parse(left: "7326401589", right: "9051837624")!, 11),
    (parse(left: "5109827346", right: "9240178635")!, 17),
    (parse(left: "4698701325", right: "8617092543")!, 29),
    (parse(left: "9410287356", right: "6509842713")!, 43)],
    parseReflector(left: "812307", right: "854697")!)
