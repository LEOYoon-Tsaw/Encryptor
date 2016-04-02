//
//  main.swift
//  Enigma
//
//  Created by LEO Yoon-Tsaw on 18/4/15.
//  Copyright (c) 2016 Yoon-Tsaw Leo. All rights reserved.
//

public enum ProcessingErrors: ErrorType {
    case invalidFormat, invalidEncryption
}
public enum ProcessDirection: String {
    case encryption, decryption
}

private func encode(input: String, configure: Configuration) throws -> String {
    let enigma1 = enigmaMachine(configure)
    let enigma2 = enigmaMachine(configure)
    var encodedText = input
    encodedText = try encoder(encodedText, machine: enigma1)
    encodedText = String(encodedText.characters.reverse())
    encodedText = try encoder(encodedText, machine: enigma2)
    return encodedText
}

private let base = 9, seperator: Character = "9"
private func transcode(input: String, prefix: String = "") -> String {
    let codes = input.unicodeScalars.map { String($0.value, radix: base) }.joinWithSeparator(String(seperator))
    return codes
}
private func reverseCode(codeString: String) throws -> String {
    let codes = codeString.characters.split(seperator).map { String($0) }
    let text = try codes.map { (code: String) throws -> String in
        if let unicode = Int(code, radix: base) where 0...0x10ffff ~= unicode {
            return String(UnicodeScalar(unicode))
        } else {
            throw ProcessingErrors.invalidEncryption
        }
    }
    return text.joinWithSeparator("")
}

public func process(input: String, configure: Configuration = rotors) throws -> (String, ProcessDirection) {
    var string: String
    var encodedText: String
    let direction: ProcessDirection
    do {
        string = try encode(input, configure: configure)
        encodedText = try reverseCode(string)
        direction = .decryption
    } catch is Errors {
        string = transcode(input)
        encodedText = try encode(string, configure: configure)
        direction = .encryption
    }
    return (encodedText, direction)
}

print("請鍵入想加密/解密的內容（若要結束請鍵入「我不玩了」）：\n")
while let inputString = readLine() where !["我不玩了", "不玩了", "結束", "I'm done", "quit", "stop"].contains(inputString) {
    guard !inputString.isEmpty else { continue }
    do {
        let (encodedText, direction) = try process(inputString)
        print("\(direction == .encryption ? "加密" : "解密")後的內容爲：\n\(encodedText)\n繼續嗎？（若要結束請鍵入「我不玩了」）\n")
    } catch is ProcessingErrors {
        print("密文有誤，解密失敗。試試別的？\n")
        continue
    } catch Errors.invalidCharacters(let character) {
        print("糟糕，出錯了！無法加密「\(character)」")
        break
    }
}
print("等你回來，再見！")