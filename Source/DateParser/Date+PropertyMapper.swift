//
//  File.swift
//  
//
//  Created by Lee Avery on 12/01/2022.
//

import Foundation

let DateParserDateNoTimestampFormat = "YYYY-MM-DD"
let DateParserTimestamp = "T00:00:00+00:00"
let DateParserDescriptionDate = "0000-00-00 00:00:00"

/**
 The type of date.

 - iso8601:       International date standard.
 - unixTimestamp: Number of seconds since Thursday, 1 January 1970.
 */
public enum DateType : Int {
    case iso8601
    case unixTimestamp
}

public extension Date {
    
    /**
     Converts the provided string into a NSDate object.

     - parameters:
     - dateString: The string to be converted, can be a ISO 8601 date or a Unix timestamp, also known as Epoch time.

     - returns:
     The parsed date.
     */
    static func fromDateString(_ dateString: String) -> Date? {
        var parsedDate: Date? = nil
        
        let dateType = dateString.dateType()
        switch dateType {
        case .iso8601:
            parsedDate = self.fromISO8601String(dateString)
        case .unixTimestamp:
            parsedDate = self.fromUnixTimestampString(dateString)
        }
        return parsedDate
    }
    
    
    static func fromISO8601String(_ dateString: String) -> Date? {
        var localDateString: String = dateString
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withDashSeparatorInDate, .withFullDate, .withColonSeparatorInTime]
        
        if (localDateString.count > 10 && localDateString.character(at: 10) == " ") {
            localDateString = localDateString.replacingOccurrences(of: " ", with: "T")
        }
        
        if (localDateString.contains("T")) {
            let _ = dateFormatter.formatOptions.insert(.withTime)
        }
        
        if (localDateString.contains("Z") || localDateString.contains("+")) {
            let _ = dateFormatter.formatOptions.insert(.withFullTime)
        }
        
        if (localDateString.contains(".")) {
            let _ = dateFormatter.formatOptions.insert(.withFractionalSeconds)
        }
        if (localDateString.count == 10) {
            dateFormatter.formatOptions = [.withFullDate]
        }
        //dateFormatter.dateFormat = "yyyyMMdd'T'HHmmssZ"
        //print("dateString: \(dateString)")
        return dateFormatter.date(from: localDateString)
        //2018-02-07 12:46:00 +0000
    }
    
    static func fromUnixTimestampNumber(_ unixTimestamp: Double) -> Date {
        return self.fromUnixTimestampString(String(unixTimestamp))
    }
    
    static func fromUnixTimestampString(_ unixTimestamp: String) -> Date {
        var parsedString = unixTimestamp

        let validUnixTimestamp = "1441843200"
        let validLength = validUnixTimestamp.count
        if unixTimestamp.count > validLength {
            parsedString = String(unixTimestamp.prefix(10))
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let unixTimestampNumber = numberFormatter.number(from: parsedString)
        let date = Date(timeIntervalSince1970: TimeInterval(unixTimestampNumber?.doubleValue ?? 0.0))

        return date
    }
    
}


public extension String {
    
    func dateType() -> DateType {
        if self.contains("-") {
            return DateType.iso8601
        }
        return DateType.unixTimestamp
    }
   
    func character(at offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
    
}


    
