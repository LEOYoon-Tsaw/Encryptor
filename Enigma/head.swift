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
    case invalidConfiguration
    case duplicationInConfiguration(elements: (T, T))
}

public typealias Configuration<T: Hashable> = ([(([T], [T]), Int)], ([T], [T]))
typealias EnigmaTranslator<T: Hashable> = (T) throws -> T

func enigmaMachine<T>(mappings: Configuration<T>) throws -> EnigmaTranslator<T> {
    var turn: UInt = 0
    var extraTurn: UInt = 0

    func rotorCreator(mapping: ([T], [T]), frequency: Int) throws -> (EnigmaTranslator<T>, EnigmaTranslator<T>) {
        let length = mapping.0.count
        guard length == mapping.1.count else {
            throw Errors<Character>.invalidConfiguration
        }
        var leftSide = mapping.0
        let rightSide = mapping.1
        var leftSearch = Dictionary(uniqueKeysWithValues: leftSide.enumerated().map { ($0.element, $0.offset) })
        let rightSearch = Dictionary(uniqueKeysWithValues: rightSide.enumerated().map { ($0.element, $0.offset) })
        
        func rotor(_ input: T) throws -> T {
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
            return rightSide[index]
        }
        func reverseRotor(_ input: T) throws -> T {
            guard let index = rightSearch[input] else {
                throw Errors.invalidElement(element: input)
            }
            extraTurn = extraTurn &+ UInt(index % 3)
            return leftSide[index]
        }
        return (rotor, reverseRotor)
    }

    func reflectorCreator(mapping: ([T], [T])) throws -> EnigmaTranslator<T> {
        var left = mapping.0, right = mapping.1
        left.append(contentsOf: mapping.1)
        right.append(contentsOf: mapping.0)
        let map = try Dictionary(zip(left, right)) { (first, second) in
            if first == second {
                return first
            } else {
                throw Errors.duplicationInConfiguration(elements: (first, second))
            }
        }
        func reflector(_ input: T) throws -> T {
            guard let output = map[input] else {
                throw Errors.invalidElement(element: input)
            }
            return output
        }
        return reflector
    }

    var encoders = try [reflectorCreator(mapping: mappings.1)]
    for (connections, frequency) in mappings.0.reversed() {
        let (frontRotor, reverseRotor) = try rotorCreator(mapping: connections, frequency: frequency)
        encoders.insert(frontRotor, at: 0)
        encoders.append(reverseRotor)
    }

    func encode(_ input: T) throws -> T {
        var output = input
        for encoder in encoders {
            output = try encoder(output)
        }
        turn = turn &+ 1 &+ extraTurn % 3
        extraTurn %= 2
        return output
    }
    return encode
}

func encode<T: Hashable>(_ input: inout [T], with machine: EnigmaTranslator<T>) throws -> Void {
    for i in 0..<input.count {
        input[i] = try machine(input[i])
    }
}
