#!/usr/bin/env swift

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let project = CommandLine.arguments[1]
let scheme = CommandLine.arguments[2]
let REPO = CommandLine.arguments[3]
let PR_NUMBER = CommandLine.arguments[4]
let GITHUB_TOKEN = CommandLine.arguments[5]
let generateScreenshots = false//CommandLine.arguments[6]
let issueURL = "https://api.github.com/repos/\(REPO)/issues/\(PR_NUMBER)/comments"

func getTestPlans() -> [String] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    let pipe = Pipe()
    var testPlans = [String]()
    process.standardOutput = pipe
    process.arguments = ["xcodebuild", "-showTestPlans", "-project", project, "-scheme", scheme]
    
    do {
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: String.Encoding.utf8) {
            guard let subRange = output.range(of: "\(scheme)\":") else {
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

let testPlans = getTestPlans()

if generateScreenshots == false {
    createIssueComment(with: testPlans)
}
