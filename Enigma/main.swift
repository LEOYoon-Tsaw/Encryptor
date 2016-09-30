//
//  main.swift
//  Enigma
//
//  Created by LEO Yoon-Tsaw on 18/4/15.
//  Copyright (c) 2016 Yoon-Tsaw Leo. All rights reserved.
//

public enum ProcessingErrors: Error {
    case invalidFormat, invalidEncryption
}
public enum ProcessDirection: String {
    case encryption, decryption
}

private func encode(_ input: String, with configure: Configuration) throws -> String {
    let enigma1 = enigmaMachine(mappings: configure)
    let enigma2 = enigmaMachine(mappings: configure)
    var encodedText = input
    encodedText = try encoder(text: encodedText, machine: enigma1)
    encodedText = String(encodedText.characters.reversed())
    encodedText = try encoder(text: encodedText, machine: enigma2)
    return encodedText
}

private let base = 9, seperator: Character = "9"
private func transcode(from input: String, prefix: String = "") -> String {
    let codes = input.unicodeScalars.map { String($0.value, radix: base) }.joined(separator: String(seperator))
    return codes
}
private func reverse(code codeString: String) throws -> String {
    let codes = codeString.characters.split(separator: seperator).map { String($0) }
    let text = try codes.map { (code: String) throws -> String in
        if let unicode = UInt32(code, radix: base), let uniChar = UnicodeScalar(unicode) {
            return uniChar.description
        } else {
            throw ProcessingErrors.invalidEncryption
        }
    }
    return text.joined()
}

public func process(_ input: String, configure: Configuration = rotors) throws -> (String, ProcessDirection) {
    var string: String
    var encodedText: String
    let direction: ProcessDirection
    do {
        string = try encode(input, with: configure)
        encodedText = try reverse(code: string)
        direction = .decryption
    } catch is Errors {
        string = transcode(from: input)
        encodedText = try encode(string, with: configure)
        direction = .encryption
    }
    return (encodedText, direction)
}

let arguments = CommandLine.arguments
if arguments.count == 1 {
    print("此乃一密碼機，用法：鍵入「Enigma 內容」，程式自動判斷加密或解密內容。\n")
} else {
    let inputString = arguments.dropFirst().joined(separator: " ")
    do {
        let (encodedText, direction) = try process(inputString)
        print("\(direction == .encryption ? "加密" : "解密")得到：\n\(encodedText)\n")
    } catch is ProcessingErrors {
        print("密文有誤，解密失敗，試試別的？\n")
    } catch Errors.invalidCharacters(let character) {
        print("糟糕，出錯了！無法加密「\(character)」\n")
    }
}
