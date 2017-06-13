//
//  head.swift
//  Enigma
//
//  Created by LEO Yoon-Tsaw on 18/4/15.
//  Copyright (c) 2017 Yoon-Tsaw Leo. All rights reserved.
//
//  Enigma Machine -- An old-fashioned encoding algorithm
//

public enum Errors<T: Hashable>: Error {
    case invalidElement(element: T)
    case duplicationInConfiguration(elements: (T, T))
}

public typealias Configuration<T: Hashable> = ([([T: T], Int)], [T: T])
typealias EnigmaTranslator<T: Hashable> = (inout T) throws -> Void

func enigmaMachine<T>(mappings: Configuration<T>) throws -> EnigmaTranslator<T> {
    var turn: UInt = 0
    var extraTurn: UInt = 0

    func rotorCreator(mapping: [T: T], frequency: Int) throws -> (EnigmaTranslator<T>, EnigmaTranslator<T>) {
        let length = mapping.count
        var leftSide = Array(mapping.keys)
        let rightSide = Array(mapping.values)
        var leftSearch = Dictionary(uniqueKeysWithValues: leftSide.enumerated().map { ($0.element, $0.offset) })
        let rightSearch = try Dictionary(rightSide.enumerated().map { ($0.element, $0.offset) }) { (first, second) in
            throw Errors.duplicationInConfiguration(elements: (rightSide[first], rightSide[second]))
        }
        
        func rotor(_ input: inout T) throws -> Void {
            if turn % UInt(frequency) == 0 {
                let first = leftSide.removeFirst()
                leftSide.append(first)
                leftSearch = leftSearch.mapValues { $0 - 1 }
                leftSearch[first] = length - 1
            }
            guard let index = leftSearch[input] else {
                throw Errors.invalidElement(element: input)
            }
            extraTurn = extraTurn &+ UInt(index % 3)
            input = rightSide[index]
        }
        func reverseRotor(_ input: inout T) throws -> Void {
            guard let index = rightSearch[input] else {
                throw Errors.invalidElement(element: input)
            }
            extraTurn = extraTurn &+ UInt(index % 3)
            input = leftSide[index]
        }
        return (rotor, reverseRotor)
    }

    func reflectorCreator(mapping: [T: T]) throws -> EnigmaTranslator<T> {
        let map = try mapping.merging(mapping.map { ($0.value, $0.key) }) { (first, second) in
            if first == second {
                return first
            } else {
                throw Errors.duplicationInConfiguration(elements: (first, second))
            }
        }
        func reflector(_ input: inout T) throws -> Void {
            guard let output = map[input] else {
                throw Errors.invalidElement(element: input)
            }
            input = output
        }
        return reflector
    }

    var encoders = try [reflectorCreator(mapping: mappings.1)]
    for (connections, frequency) in mappings.0.reversed() {
        let (frontRotor, reverseRotor) = try rotorCreator(mapping: connections, frequency: frequency)
        encoders.insert(frontRotor, at: 0)
        encoders.append(reverseRotor)
    }

    func encode(_ input: inout T) throws -> Void {
        for encoder in encoders {
            try encoder(&input)
        }
        turn = turn &+ 1 &+ extraTurn % 3
        extraTurn %= 2
    }
    return encode
}

func encode<T: Hashable>(_ input: inout [T], with machine: EnigmaTranslator<T>) throws -> Void {
    for i in 0..<input.count {
        try machine(&input[i])
    }
}
