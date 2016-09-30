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
}

public typealias Configuration = ([([Character: Character], Int)], [Character: Character])
typealias EnigmaTranslator = (Character) throws -> Character

func enigmaMachine(mappings: Configuration) -> EnigmaTranslator {
    var turn: UInt = 0
    var extraTurn: UInt = 0

    func rotorCreator(mapping: [Character: Character], frequency: Int) -> (EnigmaTranslator, EnigmaTranslator) {
        var leftSide = Array(mapping.keys)
        let rightSide = Array(mapping.values)
        func rotor(_ input: Character) throws -> Character {
            if turn % UInt(frequency) == 0 {
                let first = leftSide.removeFirst()
                leftSide.append(first)
            }
            guard let index = leftSide.index(of: input) else {
                throw Errors.invalidCharacters(character: input)
            }
            extraTurn = extraTurn &+ UInt(index % 3)
            return rightSide[index]
        }
        func reverseRotor(_ input: Character) throws -> Character {
            guard let index = rightSide.index(of: input) else {
                throw Errors.invalidCharacters(character: input)
            }
            extraTurn = extraTurn &+ UInt(index % 3)
            return leftSide[index]
        }
        return (rotor, reverseRotor)
    }

    func reflectorCreator(mapping: [Character: Character]) -> EnigmaTranslator {
        var mapping = mapping
        for (i, o) in mapping {
            mapping[o] = i
        }
        func reflector(_ input: Character) throws -> Character {
            guard let output = mapping[input] else {
                throw Errors.invalidCharacters(character: input)
            }
            return output
        }
        return reflector
    }

    var encoders = [reflectorCreator(mapping: mappings.1)]
    for (connections, frequency) in mappings.0.reversed() {
        let (frontRotor, reverseRotor) = rotorCreator(mapping: connections, frequency: frequency)
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
    var encodedText = ""
    for word in text.characters {
        let encodedWord = try machine(word)
        encodedText.append(encodedWord)
    }
    return encodedText
}
