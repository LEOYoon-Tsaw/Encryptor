//
//  resources.swift
//  Enigma
//
//  Created by LEO Yoon-Tsaw on 18/4/15.
//  Copyright (c) 2016 Yoon-Tsaw Leo. All rights reserved.
//
private func parse(_ left: String, right: String) -> Dictionary<Character, Character>? {
    guard left.characters.count == right.characters.count else { return nil }
    var rotor = Dictionary<Character, Character>()
    var rotorMirror = Dictionary<Character, Character>()
    var index = right.startIndex
    for char in left.characters {
        rotor[char] = right.characters[index]
        rotorMirror[right.characters[index]] = char
        index = right.index(after: index)
    }
    if min(rotor.count, rotorMirror.count) < left.characters.count {
        return nil
    } else {
        return rotor
    }
}

let rotors = ([(parse("3194820576", right: "7325091864")!, 1),
    (parse("6234098751", right: "5426801973")!, 2),
    (parse("6735120894", right: "0651924783")!, 3),
    (parse("2816043795", right: "6890751324")!, 5),
    (parse("7326401589", right: "9051837624")!, 11),
    (parse("5109827346", right: "9240178635")!, 17),
    (parse("4698701325", right: "8617092543")!, 29),
    (parse("9410287356", right: "6509842713")!, 43)],
    parse("812307", right: "854697")!)
