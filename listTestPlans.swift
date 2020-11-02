#!/usr/bin/env swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let testScheme = CommandLine.arguments[1]
let projectScheme = CommandLine.arguments[2]
let project = CommandLine.arguments[3]
let platform = CommandLine.arguments[4]
let configuration = CommandLine.arguments[5]
let REPO = CommandLine.arguments[6]
let PR_NUMBER = CommandLine.arguments[7]
let GITHUB_TOKEN = CommandLine.arguments[8]
let generateScreenshots = false//CommandLine.arguments[6]
let issueURL = "https://api.github.com/repos/\(REPO)/issues/\(PR_NUMBER)/comments"

func getTestPlans() -> [String] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    let pipe = Pipe()
    var testPlans = [String]()
    process.standardOutput = pipe
    process.arguments = ["xcodebuild", "-showTestPlans", "-project", project, "-scheme", testScheme]
    
    do {
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: String.Encoding.utf8) {
            guard let subRange = output.range(of: "\(testScheme)\":") else {
                return testPlans
            }
            
            let startIndex = output.index(after: subRange.upperBound)
            testPlans = String(output[startIndex...]).split(separator: " ").map { (subString) -> String in
                return subString.trimmingCharacters(in: CharacterSet.newlines)
            }
            return testPlans
        }
    } catch {
        print("Error")
        return testPlans
    }
    return testPlans
}

func createIssueComment(with markdown: String) {
    let semaphore = DispatchSemaphore (value: 0)
    let body = """
    {
    "body": "\(markdown)"
    }
    """

    let parameters = body//"{\n  \"body\": \"test\"\n}"
    let postData = parameters.data(using: .utf8)

    var request = URLRequest(url: URL(string: issueURL)!,timeoutInterval: Double.infinity)
    request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
    request.addValue("Bearer \(GITHUB_TOKEN)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    request.httpMethod = "POST"
    request.httpBody = postData

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      guard let data = data else {
        print(String(describing: error))
        return
      }
      print(String(data: data, encoding: .utf8)!)
      semaphore.signal()
    }

    task.resume()
    semaphore.wait()

}

func getMD(for testPlans: [String]) -> String {
    var md = ""
    var body = ""
    testPlans.forEach {
        md += "'**_\($0)_**'"
    }
    
    if md == "" {
        body = "No test plan found..."
    } else {
        body = "Available screenshots:  " + md + "<br><br>Comment **_screenshot:screenshot-name_** to get screenshots. <br><br>`e.g. screenshot:\(testPlans[0])`"
    }
    
    return body
}

let testPlans = getTestPlans()
if generateScreenshots == false {
    createIssueComment(with: getMD(for: testPlans))
}
