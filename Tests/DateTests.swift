import XCTest
import Sync

class DateTests: XCTestCase {

    func testDateA() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-06-23T12:40:08.123")
        let resultDate = Date.fromDateString("2015-06-23T14:40:08.123+02:00")

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date.timeIntervalSince1970, resultDate?.timeIntervalSince1970)
    }

    func testDateB() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2014-01-01T12:40:08.000")
        let resultDate = Date.fromDateString("2014-01-01T12:40:08+00:00")!

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateC() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2014-01-02T00:00:00.000")
        let resultDate = Date.fromDateString("2014-01-02")!

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateD() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2014-01-02T12:40:08.123")
        let resultDate = Date.fromDateString("2014-01-02T12:40:08.123000+00:00")!

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateE() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.123")
        let resultDate = Date.fromDateString("2015-09-10T12:40:08.123+0000")!

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateF() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.123")
        let resultDate = Date.fromDateString("2015-09-10T12:40:08.123456Z")!

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateG() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-06-23T19:04:19.911Z")
        let resultDate = Date.fromDateString("2015-06-23T19:04:19.911Z")!
        print(date.timeIntervalSince1970)
        print(resultDate.timeIntervalSince1970)
        date.prettyPrint()

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateH() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2014-03-30T09:13:10.000Z")
        let resultDate = Date.fromDateString("2014-03-30T09:13:10Z")!
        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateI() {
        let resultDate = Date.fromDateString("2014-01-02T00:monsterofthelakeI'mhere00:00.007450+00:00")
        XCTAssertNil(resultDate)
    }

    func testDateJ() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2016-01-09T12:40:08.120")
        let resultDate = Date.fromDateString("2016-01-09T12:40:08.12")!
        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateK() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2016-01-09T12:40:08.000")
        let resultDate = Date.fromDateString("2016-01-09T12:40:08")!
        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateL() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2009-10-09T12:40:08.000")
        let resultDate = Date.fromDateString("2009-10-09 12:40:08")!
        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateM() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2017-12-22T18:10:14.070")
        let resultDate = Date.fromDateString("2017-12-22T18:10:14.07Z")!
        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateN() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2017-11-02T17:27:52.200")
        let resultDate = Date.fromDateString("2017-11-02T17:27:52.2Z")!
        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }
    
    func testDateO() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2017-12-22T18:10:14.070")
        let resultDate = Date.fromDateString("2017-12-22T18:10:14.070")!
        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

}

class TimestampDateTests: XCTestCase {

    func testTimestampA() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.000")
        let resultDate = Date.fromDateString("1441888808")!

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testTimestampB() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.000")
        let resultDate = Date.fromDateString("1441888808000000")!

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testTimestampC() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.000")
        let resultDate = Date.fromUnixTimestampNumber(1441888808)

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testTimestampD() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.000")
        let resultDate = Date.fromUnixTimestampNumber( 1441888808000000.0)

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }
}

class OtherDateTests: XCTestCase {

    func testDateType() {
        let isoDateType = "2014-01-02T00:00:00.007450+00:00".dateType()
        XCTAssertEqual(isoDateType, DateType.iso8601)

        let timestampDateType = "1441843200000000".dateType()
        XCTAssertEqual(timestampDateType, DateType.unixTimestamp)
    }
}

extension Date {
    static func dateWithHourAndTimeZoneString(dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let date = formatter.date(from: dateString)!

        return date
    }

    func prettyPrint() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let string = formatter.string(from: self)
        print(string)
    }
}
