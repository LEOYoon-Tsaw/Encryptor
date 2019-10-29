//
//  main.swift
//  Enigma
//
//  Created by LEO Yoon-Tsaw on 18/4/15.
//  Copyright (c) 2017 Yoon-Tsaw Leo. All rights reserved.
//

import Foundation

public enum ProcessingErrors: Error {
    case invalidFormat, invalidEncryption
    case invalidFilePath(path: String)
}
public enum ProcessDirection: String {
    case encryption, decryption
}

private func encode(_ input: String, with configure: Configuration<Character>) throws -> String {
    let enigma1 = try enigmaMachine(mappings: configure)
    let enigma2 = try enigmaMachine(mappings: configure)
    var encodedText = Array(input)
    
    try encode(&encodedText, with: enigma1)
    encodedText.reverse()
    try encode(&encodedText, with: enigma2)
    return String(encodedText)
}

private func transcode(from input: String, prefix: String = "") -> String {
    let codes = input.unicodeScalars.map { String($0.value, radix: base) }.joined(separator: String(seperator))
    return codes
}
private func reverse(code codeString: String) throws -> String {
    let codes = codeString.split(separator: seperator).map { String($0) }
    let text = try codes.map { (code: String) throws -> Character in
        if let unicode = UInt32(code, radix: base), let uniChar = UnicodeScalar(unicode) {
            return Character(uniChar)
        } else {
            throw ProcessingErrors.invalidEncryption
        }
    }
    return String(text)
}

public func process(_ input: String, with configure: Configuration<Character> = rotors) throws -> (String, ProcessDirection) {
    var string: String
    var encodedText: String
    let direction: ProcessDirection
    do {
        string = try encode(input, with: configure)
        encodedText = try reverse(code: string)
        direction = .decryption
    } catch is Errors<Character> {
        string = transcode(from: input)
        encodedText = try encode(string, with: configure)
        direction = .encryption
    }
    return (encodedText, direction)
}

func pathToURL(_ path: String) throws -> URL {
    let userDir = FileManager.default.homeDirectoryForCurrentUser
    if path.hasPrefix("~") {
        if let pathStartIndex = path.firstIndex(of: "/") {
            let newPath = path[path.index(after: pathStartIndex)...]
            return userDir.appendingPathComponent(String(newPath))
        } else {
            throw ProcessingErrors.invalidFilePath(path: path)
        }
    } else {
        return URL(fileURLWithPath: path)
    }
}

let arguments = CommandLine.arguments
if arguments.count == 1 {
    print("This is an encryption tool, to use, type 'enigma <string>', it will be automatically encoded or decoded based on the nature of the string.")
} else if arguments[1] != "-f" {
    let inputString = arguments.dropFirst().joined(separator: " ")
    do {
        let (encodedText, direction) = try process(inputString)
        print("\(direction == .encryption ? "Encoded string" : "Decoded message"):\n\(encodedText)")
    } catch is ProcessingErrors {
        fputs("The encrypted string is corrupted, please try another one!\n", stderr)
    } catch Errors<Character>.invalidElement(let element) {
        fputs("Oops, The character '\(element)' cannot be encoded!\n", stderr)
    } catch Errors<Character>.duplicationInConfiguration(let elements) {
        fputs("Oops, the encryption configuration is duplicated! '\(elements.0)', '\(elements.1)' are the same.\n", stderr)
    } catch Errors<Character>.invalidConfiguration {
        fputs("Oops, the encryption configuration is invalid!\n", stderr)
    }
} else {
    do {
        guard arguments.count == 4 else {
            fputs("Invalid arguments.\nUsage: enigma -f <source file> <target file>\n", stderr)
            exit(1)
        }
        let sourceFile = try pathToURL(arguments[2])
        let contents: String
        do {
            contents = try String(contentsOf: sourceFile, encoding: .utf8)
        } catch {
            throw ProcessingErrors.invalidFilePath(path: String(sourceFile.absoluteString.dropFirst(7)))
        }
        let (encodedText, direction) = try process(contents)
        
        let targetFile = try pathToURL(arguments[3])
        do {
            try encodedText.write(to: targetFile, atomically: false, encoding: .utf8)
        } catch {
            throw ProcessingErrors.invalidFilePath(path: String(targetFile.absoluteString.dropFirst(7)))
        }
        print("\(direction == .encryption ? "Encoded" : "Decoded") file saved to:\n\(String(targetFile.absoluteString.dropFirst(7)))")
    } catch ProcessingErrors.invalidFilePath(let path) {
        fputs("Invalid path: \(path)\n", stderr)
    } catch is ProcessingErrors {
        fputs("The encrypted string is corrupted, please try another one!\n", stderr)
    } catch Errors<Character>.invalidElement(let element) {
        fputs("Oops, The character '\(element)' cannot be encoded!\n", stderr)
    } catch Errors<Character>.duplicationInConfiguration(let elements) {
        fputs("Oops, the encryption configuration is duplicated! '\(elements.0)', '\(elements.1)' are the same.\n", stderr)
    } catch Errors<Character>.invalidConfiguration {
        fputs("Oops, the encryption configuration is invalid!\n", stderr)
    }
}
