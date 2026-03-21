//
//  gcode2_test.swift
//  FHLBible
//
//  Created by littlesnow on 2026/3/2.
//

import XCTest

@testable import FHLBible
@testable import FHLCommon

class GCode2_Test : XCTestCase {
    private let serverHost = "192.168.0.116"
    private let serverPort = 5600

    func testFetchLocalAPI() async throws {
        try await ensureServerAvailableOrSkip()

        let url = try XCTUnwrap(URL(string: "http://\(serverHost):\(serverPort)/"))

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertTrue((200...299).contains(httpResponse.statusCode), "HTTP 狀態碼: \(httpResponse.statusCode)")
        XCTAssertFalse(data.isEmpty, "回傳資料為空")
    }

    func testGCode2RealCasesAgainstLocalAPI() async throws {
        try await ensureServerAvailableOrSkip()
        
        // (book, chap, sec, count)
        let startCases: [(Int, Int, Int, Int)] = [
            (40, 1, 1, 1),
            (40, 1, 1, 1),
            (40, 10, 16, 1),
            (40, 16, 25, 1),
            (40, 18, 21, 1),
            (41, 3, 15, 10),
        ]

        for (startBook, startChap, startSec, count) in startCases {
            var book = startBook
            var chap = startChap
            var sec = startSec

            for _ in 0..<count {
                let payload = try await fetchAPIResult(book: book, chap: chap, sec: sec)

                let expected = normalizeNewline(payload.api)
                let input = payload.sqlite
                let actual = normalizeNewline(gcode2(input))

                let expectedNoSpace = removeAllWhitespaces(expected)
                let actualNoSpace = removeAllWhitespaces(actual)

                if expectedNoSpace != actualNoSpace {
                    let msg = genErrorMsg(
                        book: book,
                        chap: chap,
                        sec: sec,
                        expected: expected,
                        actual: actual,
                        input: input
                    )
                    XCTFail(msg)
                    return
                } else {
                    print("\(book):\(chap):\(sec) okay")
                }

                guard let next = GetNextAddress.getNextAddress([
                    "book": book,
                    "chap": chap,
                    "verse": sec
                ]) else {
                    break
                }

                book = next[0]
                chap = next[1]
                sec = next[2]
            }
        }
    }

    // MARK: - Helpers
    private func ensureServerAvailableOrSkip() async throws {
        let ok = await isServerAvailable()
        if !ok {
            let msg = "⚠️ 協同測試 server 未開啟（\(serverHost):\(serverPort)）。本次測試已略過；失敗原因僅為 server 沒開。"
            print(msg)
            throw XCTSkip(msg)
        }
    }

    private func isServerAvailable() async -> Bool {
        guard let url = URL(string: "http://\(serverHost):\(serverPort)/") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 2

        do {
            let (_, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200...599).contains(http.statusCode)
        } catch {
            return false
        }
    }
    private struct SwiftTestResponse: Decodable {
        let api: String
        let sqlite: String
        let gcode2: String?
    }

    private func fetchAPIResult(book: Int, chap: Int, sec: Int) async throws -> SwiftTestResponse {
        var components = URLComponents()
        components.scheme = "http"
        components.host = serverHost
        components.port = serverPort
        components.path = "/gcode2/swift_test.php"
        components.queryItems = [
            URLQueryItem(name: "book", value: "\(book)"),
            URLQueryItem(name: "chap", value: "\(chap)"),
            URLQueryItem(name: "sec", value: "\(sec)")
        ]

        let url = try XCTUnwrap(components.url)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        let http = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertTrue((200...299).contains(http.statusCode), "HTTP 狀態碼: \(http.statusCode) @ \(book):\(chap):\(sec)")

        return try JSONDecoder().decode(SwiftTestResponse.self, from: data)
    }

    private func normalizeNewline(_ text: String) -> String {
        text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    private func removeAllWhitespaces(_ text: String) -> String {
        text.replacingOccurrences(of: #"\s+"#, with: "", options: .regularExpression)
    }

    private func firstDiff(_ a: String, _ b: String) -> (index: Int, aChar: Character?, bChar: Character?) {
        let aa = Array(a)
        let bb = Array(b)
        let n = min(aa.count, bb.count)

        for i in 0..<n where aa[i] != bb[i] {
            return (i, aa[i], bb[i])
        }
        if aa.count != bb.count {
            return (n, aa.count > n ? aa[n] : nil, bb.count > n ? bb[n] : nil)
        }
        return (-1, nil, nil)
    }

    private func scalarDesc(_ c: Character?) -> String {
        guard let c else { return "EOF" }
        let s = String(c)
        if let u = s.unicodeScalars.first {
            return "\(String(reflecting: s)) U+\(String(format: "%04X", u.value))"
        }
        return String(reflecting: s)
    }

    private func genErrorMsg(book: Int, chap: Int, sec: Int, expected: String, actual: String, input: String) -> String {
        let d = firstDiff(expected, actual)
        return """
        txt1 != txt2b at \(book):\(chap):\(sec)

        input:
        \(input)

        expected:
        \(expected)

        result:
        \(actual)

        first diff index: \(d.index)
        expected: \(scalarDesc(d.aChar))
        result  : \(scalarDesc(d.bChar))
        """
    }    
}
