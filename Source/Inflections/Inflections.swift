//
//  File.swift
//  
//
//  Created by Lee Avery on 18/01/2022.
//

import Foundation

var snakeCaseStorage: Dictionary<String, String> = Dictionary()
var camelCaseStorage: Dictionary<String, String> = Dictionary()
let acronyms: Array = ["uuid", "id", "pdf", "url", "png", "jpg", "uri", "json", "xml"]


public extension String {

    
    func hyp_snakeCase() -> String {
 //       let storedResult: String? = snakeCaseStorage[self]
        
//        if storedResult != nil {
            let firstLetterLowercase = self.hyp_lowerCaseFirstLetter()
            let result = firstLetterLowercase.hyp_replaceIdentifierWithString("_")
            snakeCaseStorage.updateValue(result, forKey: self)
            return result
 //       }
 //       return storedResult!
        
    }
    
    func hyp_camelCase() -> String? {

            var result: String?
            if self.contains("_") {
                var processedString = self
                processedString = processedString.hyp_replaceIdentifierWithString("")
                let remoteStringIsAcronym = acronyms.contains(processedString.lowercased())
                result = (remoteStringIsAcronym) ? processedString.lowercased() : processedString.hyp_lowerCaseFirstLetter()
            } else {
                result = self.hyp_lowerCaseFirstLetter()
            }
            camelCaseStorage.updateValue(result!, forKey: self)
        
        return result == "" ? nil : result
 
    }
    
    
    func hyp_containsWord(word: String) -> Bool {
        var found = false
        let components = self.components(separatedBy: "_")
        
        for component in components {
            if component == word {
                found = true
                break
            }
        }
        return found
    }
    
    func hyp_lowerCaseFirstLetter() -> String {
        var mutableString = self
        if mutableString.count > 0 {
            let firstLetter = (mutableString.first!).lowercased()
            
            mutableString = firstLetter + mutableString.dropFirst()
        }
        return mutableString
    }
    
    func hyp_replaceIdentifierWithString(_ replacementString: String) -> String {
        let scanner: Scanner = Scanner.localizedScanner(with: self) as! Scanner
        scanner.caseSensitive = true
        
        var identifierSet: CharacterSet = CharacterSet()
        identifierSet.insert(charactersIn: "_- ")
        let alphanumerisSet: CharacterSet = CharacterSet.alphanumerics
        let uppercaseSet: CharacterSet = CharacterSet.uppercaseLetters
        let lowercaseLettersSet: CharacterSet = CharacterSet.lowercaseLetters
        let decimaldigitSet: CharacterSet = CharacterSet.decimalDigits
        
        var mutableLowercaseSet: CharacterSet = CharacterSet()
        mutableLowercaseSet.formUnion(lowercaseLettersSet)
        mutableLowercaseSet.formUnion(decimaldigitSet)
        let lowercaseSet = mutableLowercaseSet
        
        var buffer: NSString? = ""
        var stringBuffer: String = ""
        var output: String = ""
        
        while !(scanner.isAtEnd) {
            let isExcludedCharacter = scanner.scanCharacters(from: identifierSet, into: &buffer)
            if (isExcludedCharacter) { continue }
            
            if (replacementString.count > 0) {
                let isUppercaseCharacter = scanner.scanCharacters(from: uppercaseSet, into: &buffer)
                stringBuffer = buffer! as String
                if (isUppercaseCharacter) {
                    for eachString in acronyms {
                        let containsString = (stringBuffer.lowercased().range(of: eachString))
                        if (containsString != nil) {
                            if (stringBuffer.count == eachString.count) {
                                stringBuffer = eachString
                            } else {
                                stringBuffer = eachString + "_" + (stringBuffer.lowercased().replacingOccurrences(of: eachString, with: ""))
                            }
                            break
                        }
                    }
                    output.append(replacementString)
                    output.append(stringBuffer.lowercased())
                }
                
                let isLowercasedCharacter = scanner.scanCharacters(from: lowercaseSet, into: &buffer)
                stringBuffer = buffer! as String
                if (isLowercasedCharacter) {
                    output.append(stringBuffer.lowercased())
                }
            } else if (scanner.scanCharacters(from: alphanumerisSet, into: &buffer)) {
                stringBuffer = buffer! as String
                if (acronyms.contains(stringBuffer)) {
                    output.append(stringBuffer.uppercased())
                } else {
                    output.append(stringBuffer.capitalized)
                }
            } else {
                output = ""
                break
            }
        }
      

        return output
    }
    
    
}
