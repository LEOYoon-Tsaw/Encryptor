//
//  head.swift
//  Enigma
//
//  Created by LEO Yoon-Tsaw on 18/4/15.
//  Copyright (c) 2016 Yoon-Tsaw Leo. All rights reserved.
//
//  Enigma Machine -- An old-fashioned encoding algorithm
//

public enum Errors: Error {
    case invalidCharacters(character: Character)
    case duplicationInConfiguration(characters: (Character, Character))
}

public typealias Configuration = ([([Character: Character], Int)], [Character: Character])
typealias EnigmaTranslator = (Character) throws -> Character

func enigmaMachine(mappings: Configuration) throws -> EnigmaTranslator {
    var turn: UInt = 0
    var extraTurn: UInt = 0

    func rotorCreator(mapping: [Character: Character], frequency: Int) throws -> (EnigmaTranslator, EnigmaTranslator) {
        let length = mapping.count
        var leftSide = Array(mapping.keys)
        let rightSide = Array(mapping.values)
        var leftSearch = Dictionary(uniqueKeysWithValues: leftSide.enumerated().map { ($0.element, $0.offset) })
        let rightSearch = try Dictionary(rightSide.enumerated().map { ($0.element, $0.offset) }) { (first, second) in
            throw Errors.duplicationInConfiguration(characters: (rightSide[first], rightSide[second]))
        }
        
        func rotor(_ input: Character) throws -> Character {
            if turn % UInt(frequency) == 0 {
                let first = leftSide.removeFirst()
                leftSide.append(first)
                leftSearch = leftSearch.mapValues { $0 - 1 }
                leftSearch[first] = length - 1
            }
            guard let index = leftSearch[input] else {
                throw Errors.invalidCharacters(character: input)
            }
            extraTurn = extraTurn &+ UInt(index % 3)
            return rightSide[index]
        }
        func reverseRotor(_ input: Character) throws -> Character {
            guard let index = rightSearch[input] else {
                throw Errors.invalidCharacters(character: input)
            }
            extraTurn = extraTurn &+ UInt(index % 3)
            return leftSide[index]
        }
        return (rotor, reverseRotor)
    }

    func reflectorCreator(mapping: [Character: Character]) throws -> EnigmaTranslator {
        let map = try mapping.merging(mapping.map { ($0.value, $0.key) }) { (first, second) in
            if first == second {
                return first
            } else {
                throw Errors.duplicationInConfiguration(characters: (first, second))
            }
        }
        func reflector(_ input: Character) throws -> Character {
            guard let output = map[input] else {
                throw Errors.invalidCharacters(character: input)
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

    func encode(_ input: Character) throws -> Character {
        var character = input
        for encoder in encoders {
            let output = try encoder(character)
            character = output
        }
        turn = turn &+ 1 &+ extraTurn % 3
        extraTurn = extraTurn % 2
        return character
    }
    return encode
}

func encoder(text: String, machine: EnigmaTranslator) throws -> String {
    return try String(text.map { try machine($0) })
}
