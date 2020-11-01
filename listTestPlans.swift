#!/usr/bin/env swift

import Foundation

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
