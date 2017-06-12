//
//  main.swift
//  Enigma
//
//  Created by LEO Yoon-Tsaw on 18/4/15.
//  Copyright (c) 2017 Yoon-Tsaw Leo. All rights reserved.
//

public enum ProcessingErrors: Error {
    case invalidFormat, invalidEncryption
}
public enum ProcessDirection: String {
    case encryption, decryption
}

private func encode(_ input: String, with configure: Configuration<Character>) throws -> String {
    let enigma1 = try enigmaMachine(mappings: configure)
    let enigma2 = try enigmaMachine(mappings: configure)
    var encodedText = input
    encodedText = try String(encoder(text: Array(encodedText), machine: enigma1))
    encodedText = String(encodedText.characters.reversed())
    encodedText = try String(encoder(text: Array(encodedText), machine: enigma2))
    return encodedText
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

let arguments = CommandLine.arguments
if arguments.count == 1 {
    print("此乃一密碼機，用法：鍵入「Enigma 內容」，程式自動判斷加密或解密內容。")
} else {
    let inputString = arguments.dropFirst().joined(separator: " ")
    do {
        let (encodedText, direction) = try process(inputString)
        print("\(direction == .encryption ? "加密" : "解密")得到：\n\(encodedText)")
    } catch is ProcessingErrors {
        print("密文有誤，解密失敗，試試別的？")
    } catch Errors<Character>.invalidElement(let element) {
        print("糟糕，出錯了！無法加密「\(element)」")
    } catch Errors<Character>.duplicationInConfiguration(let elements) {
        print("糟糕，出錯了！密碼機內部故障，「\(elements.0)」、「\(elements.1)」重複")
    }
}
