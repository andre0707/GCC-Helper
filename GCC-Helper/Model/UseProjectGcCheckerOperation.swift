//
//  UseProjectGcCheckerOperation.swift
//  GCC-Helper
//
//  Created by Andre Albach on 25.11.21.
//

import Foundation
import WebKit

/// The operation which will perform a project-gc.com checker check.
/// Pass in the log which holds the information to check and the webView used to perform the check
class UseProjectGcCheckerOperation: AsyncOperation {
    
    /// The log which should be checked
    private(set) var log: GcLog
    /// Reference to the web view on which the operation runs
    let webView: WKWebView
    
    
    /// Init the operation
    /// - Parameters:
    ///   - log: The log holding the information used for the project-gc challenge checker
    ///   - webView: The webView in which the checker runs
    init(log: GcLog, webView: WKWebView) {
        self.log = log
        self.webView = webView
    }
    
    /// The main function which executes
    override func main() {
        
        /// Javascript to set the username from the log and start the check
        let javaScript = #"""
            document.getElementById("profile_name_fill").setAttribute("value", "$$$USERNAME$$$");
            document.getElementById("profile_name_fill").click();
            document.getElementById("runChecker").click();
        """#
            .replacingOccurrences(of: "$$$USERNAME$$$", with: "\(log.name)")
        
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(javaScript) { [weak self] result, error in
                if let error = error {
                    self?.state = .finished
                    print(error)
                    return
                }
                
                /// Give the checker some time to run and then read the checker result
                DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                    let javaScript = #"document.getElementById('challengeFulfilled').getAttribute('style');"#
                    
                    DispatchQueue.main.async {
                        self?.webView.evaluateJavaScript(javaScript) { [weak self] result, error in
                            if let error = error {
                                self?.state = .finished
                                print(error)
                                return
                            }
                            
                            if let result = result as? String {
                                self?.log.fulfilsChallenge = !result.lowercased().contains("none")
                            }
                            self?.state = .finished
                        }
                    }
                }
            }
        }
    }
}
