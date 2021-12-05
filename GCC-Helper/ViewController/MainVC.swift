//
//  MainVC.swift
//  GCC-Helper
//
//  Created by Andre Albach on 24.11.21.
//

import Cocoa
import WebKit

/// The main view controller
class MainVC: NSViewController {
    
    // MARK:- Variables
    
    /// The list of logs which were read from the geocaching website
    private var logsFromWebsite: [GcLog] = [] {
        didSet {
            updateButtonStatus()
        }
    }
    
    /// The index of the selectedRow, if there is one selected in the table
    /// This also provides a range check
    private var selectedRowIndex: Int? {
        let index = tableView.selectedRow
        guard index >= 0, index < logsFromWebsite.count else { return nil }
        return index
    }
    
    /// The operation queue on which all the operations will run
    private var operationQueue: OperationQueue = {
       let queue = OperationQueue()
        /// The operations to execute must be in order, because the webView is needed
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    /// Indicator, if the current opened website in the webView is a geocache on geocaching.com website
    private var isGeocachingWebsiteOpen: Bool {
        guard let url = webView.url, url.absoluteString.lowercased().contains("geocaching.com/geocache") else { return false }
        return true
    }
    
    /// Indicator, if the current opened website in the webView is a challenge checker on project-gc.com website
    private var isProjectGcWebsiteOpen: Bool {
        guard let url = webView.url, url.absoluteString.lowercased().contains("project-gc.com/challenges") else { return false }
        return true
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    
    // MARK: - Outlets
    
    /// The main web view which will display the websites
    @IBOutlet weak var webView: WKWebView!
    /// The main table view which will display the geocacher names and the challenge status
    @IBOutlet weak var tableView: NSTableView!
    /// The button to read the logs from the geocaching website
    @IBOutlet weak var buttonReadLogs: NSButton!
    /// The button to check the challenge status for all geocacher in the table view
    @IBOutlet weak var buttonCheckAllUser: NSButton!
    /// The button to check the challenge status of the current selected user in the table view
    @IBOutlet weak var buttonCheckUser: NSButton!
    /// The button to open the log the current selected user wrote on the challenge cache
    @IBOutlet weak var buttonOpenLog: NSButton!
    /// The button to open a geocaching messenger chat the current selected user
    @IBOutlet weak var buttonMessageUser: NSButton!
    /// The button to open the url in the text field
    @IBOutlet weak var buttonUrlGo: NSButton!
    /// The text field which holds the url the user can enter and navigate to
    @IBOutlet weak var textFieldUrl: NSTextField!
    /// The text view which holds log events
    @IBOutlet weak var textViewLogs: NSTextView!
    /// The combobox where the user can select how long he wants to wait for the challenge checker
    @IBOutlet weak var comboBoxCheckerWaitingTime: NSComboBox!
    
    
    // MARK: Functions
    
    /// Called when the view did load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        
        openReadme()
        
        comboBoxCheckerWaitingTime.delegate = self
        comboBoxCheckerWaitingTime.removeAllItems()
        let values: [Double] = [2, 5, 10, 15, 20, 30, 40, 45, 60, 65, 70]
        comboBoxCheckerWaitingTime.addItems(withObjectValues: values)
        let indexToSelect = values.firstIndex(of: UserDefaults.standard.checkerWaitingTime) ?? 1
        comboBoxCheckerWaitingTime.selectItem(at: indexToSelect)

        textFieldUrl.becomeFirstResponder()
        textFieldUrl.isAutomaticTextCompletionEnabled = false
        textFieldUrl.placeholderString = "Enter a website"
        textFieldUrl.stringValue = "https://www.geocaching.com/"
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = false
        
        updateButtonStatus()
    }
    
    /// Use this function to display the readme file in the main browser
    func openReadme() {
        if let readmeUrl = Bundle.main.url(forResource: "README", withExtension: "md") {
            webView.loadFileURL(readmeUrl, allowingReadAccessTo: readmeUrl)
        }
    }

    
    // MARK: - Actions

    /// The button click action which is executed when the `Read Logs` button is clicked
    /// - Parameter sender: The clicked button
    @IBAction func onButtonReadLogs(_ sender: NSButton) {
        logsFromWebsite = []
        tableView.reloadData()
        
        readLogsFromWebsite()
    }
    
    /// The button click action which is executed when the `Check User` button is clicked
    /// - Parameter sender: The clicked button
    @IBAction func onButtonCheckUser(_ sender: NSButton) {
        checkCurrentSelectedUser()
    }
    
    /// The button click action which is executed when the `Check All User` button is clicked
    /// - Parameter sender: The clicked button
    @IBAction func onButtonCheckAllUser(_ sender: NSButton) {
        checkAllUser()
    }
    
    /// The button click action which is executed when the `Message User` button is clicked
    /// - Parameter sender: The clicked button
    @IBAction func onButtonMessageUser(_ sender: NSButton) {
        guard let index = selectedRowIndex else { return }
        
        guard let url = URL(string: logsFromWebsite[index].messageUserUrl) else { return }
        logOnConsole("loading \(url)")
        webView.load(URLRequest(url: url))
    }
    
    /// The button click action which is executed when the `Open Log` button is clicked
    /// - Parameter sender: The clicked button
    @IBAction func onButtonOpenLog(_ sender: NSButton) {
        guard let index = selectedRowIndex else { return }
        
        guard let url = URL(string: logsFromWebsite[index].logLink) else { return }
        logOnConsole("loading \(url)")
        webView.load(URLRequest(url: url))
    }
    
    /// The button click action which is executed when the `Go` button is clicked
    /// - Parameter sender: The clicked button
    @IBAction func onButtonUrlGo(_ sender: NSButton) {
        let input = textFieldUrl.stringValue.lowercased().starts(with: "http") ? textFieldUrl.stringValue : "https://" + textFieldUrl.stringValue
        guard let url = URL(string: input)
        else {
            logOnConsole("invalid url: \(input)")
            return
        }
        let request = URLRequest(url: url)
        logOnConsole("loading \(url)")
        webView.load(request)
    }
    
    
    // MARK: - Functions: Private
    
    /// This function will read the logs from the current website.
    /// The current website must be a geocaching.com website
    private func readLogsFromWebsite() {
        guard isGeocachingWebsiteOpen else { return }
        
        /// This java script will return a list of the cacher who wrote logs json encoded
        let javaScript = #"""
            function analyseLogs() {
                let logRows = document.getElementById('cache_logs_table').getElementsByTagName('tr');
        
                var logs = [];

                logRows.forEach( (row) => {
                    try {
                    
                        let cacherName = row.getElementsByClassName('FloatLeft LogDisplayLeft')[0].children[0].innerText;
                        let nameId = row.getElementsByClassName('FloatLeft LogDisplayLeft')[0].children[0].href.replace('https://www.geocaching.com/profile/?guid=', '');
                        let logType = row.getElementsByClassName('FloatLeft LogDisplayRight')[0].getElementsByClassName('log-meta')[0].children[0].attributes.src.textContent.replace('/images/logtypes/', '').replace('.png', '');
                        let logLink = row.getElementsByClassName('FloatLeft LogDisplayRight')[0].getElementsByClassName('log-cta')[0].getElementsByClassName('AlignRight')[0].getElementsByTagName('a')[0].href;

                        let logObject = {
                            name: cacherName,
                            nameId: nameId,
                            logType: parseInt(logType),
                            logLink: logLink
                        };
                        logs.push(logObject);
                    }
                    catch {
                    }
                });
        
                return logs;
            }

            JSON.stringify(analyseLogs());

        """#
      
        webView.evaluateJavaScript(javaScript) { [weak self] result, error in
            if let error = error {
                self?.logOnConsole(error.localizedDescription)
                return
            }
            
            guard let jsonString = result as? String,
                let jsonData = jsonString.data(using: .utf8)
            else { return }
            
            do {
                self?.logsFromWebsite = try JSONDecoder().decode([GcLog].self, from: jsonData)
                    .filter { $0.logType == GcLog.LogType.found.rawValue }
                self?.tableView.reloadData()
                self?.selectNextUser()
            } catch {
                self?.logOnConsole(error.localizedDescription)
            }
        }
    }
    
    /// The completion block which should be executed when a user was checked with the project-gc challenge check operation
    /// - Parameter log: The log information which were used for the check
    private func completeCheckerOperation(for log: GcLog) {
        DispatchQueue.main.async {
            guard let index = self.logsFromWebsite.firstIndex(where: { $0.id == log.id }) else { return }
            self.logsFromWebsite[index].fulfilsChallenge = log.fulfilsChallenge
            self.reloadRow(at: index)
            self.selectNextUser()
        }
    }
    
    /// This function will use the log data from the current selected user in the table view and perform the challenge check
    private func checkCurrentSelectedUser() {
        guard isProjectGcWebsiteOpen else { return }
        guard let index = selectedRowIndex else { return }
        
        let operation = UseProjectGcCheckerOperation(log: logsFromWebsite[index], webView: webView)
        operation.completionBlock = { [weak self] in
            self?.completeCheckerOperation(for: operation.log)
        }
        operationQueue.addOperation(operation)
    }
    
    
    /// The operation to check the logs of all user in the table vie
    private func checkAllUser() {
        guard isProjectGcWebsiteOpen else { return }
        
        if buttonCheckAllUser.title == "Check All User" {
            buttonCheckAllUser.title = "Cancel"
            
            for log in logsFromWebsite {
                let operation = UseProjectGcCheckerOperation(log: log, webView: webView)
                operation.completionBlock = { [weak self] in
                    if operation.wasCancelled { return }
                    
                    self?.completeCheckerOperation(for: operation.log)
                }
                operationQueue.addOperation(operation)
            }
            
        } else {
            buttonCheckAllUser.title = "Check All User"
            operationQueue.cancelAllOperations()
        }
    }
    
    /// This will reload the current row to display potential changes
    private func reloadCurrentRow() {
        guard let currentIndex = selectedRowIndex else { return }
        reloadRow(at: currentIndex)
    }
    
    /// This will reload the row at `index`
    /// - Parameter index: The index of the row which should be reloaded
    private func reloadRow(at index: Int) {
        tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
    }
    
    /// Tis function will select the next user in the table view if possible
    private func selectNextUser() {
        let currentIndex = selectedRowIndex ?? -1
        let nextIndex = currentIndex + 1
        guard nextIndex < logsFromWebsite.count else { return }
        
        tableView.selectRowIndexes(IndexSet(integer: nextIndex), byExtendingSelection: false)
    }
    
    /// Use this function to update the enable/disable status of the buttons
    private func updateButtonStatus() {
        buttonReadLogs.isEnabled = isGeocachingWebsiteOpen
        
        let isRowSelected = !logsFromWebsite.isEmpty && selectedRowIndex != nil
        buttonOpenLog.isEnabled = isRowSelected
        buttonMessageUser.isEnabled = isRowSelected
        
        buttonCheckUser.isEnabled = isRowSelected && isProjectGcWebsiteOpen
        buttonCheckAllUser.isEnabled = isRowSelected && isProjectGcWebsiteOpen
    }
    
    /// Use this function to write something to the error console
    /// - Parameter text: The text which should be added
    private func logOnConsole(_ text: String) {
        let logText = "\(Self.dateFormatter.string(from: Date())): \(text)\n"
        print(logText)
        textViewLogs.string += logText
        textViewLogs.scrollToEndOfDocument(nil)
    }
}


// MARK: - WKNavigationDelegate

extension MainVC: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let newUrl = webView.url?.absoluteString else { return }
        DispatchQueue.main.async {
            if !newUrl.starts(with: "file") {
                self.logOnConsole("finished loading \(newUrl)")
                self.textFieldUrl.stringValue = newUrl
            }
            self.updateButtonStatus()
        }
    }
}


// MARK: - NSTableViewDelegate

extension MainVC: NSTableViewDelegate {
    
    /// Cell identifier like in storyboard
    private enum CellIdentifiers {
        static let log = "logCell"
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let log = logsFromWebsite[row]
        
        switch tableColumn {
            case tableView.tableColumns[0]:
                guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: CellIdentifiers.log), owner: nil) as? NSTableCellView else { return nil }
                cell.textField?.stringValue = log.name
                if let checked = log.fulfilsChallenge {
                    cell.imageView?.image = NSImage(systemSymbolName: checked ? "checkmark" : "xmark", accessibilityDescription: nil)
                    cell.imageView?.contentTintColor = checked ? .green : .red
                } else {
                    cell.imageView?.image = NSImage(systemSymbolName: "questionmark", accessibilityDescription: nil)
                    cell.imageView?.contentTintColor = NSColor.textColor
                }
                return cell
                
            default:
                return nil
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        updateButtonStatus()
    }
}


// MARK: - NSTableViewDataSource

extension MainVC: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return logsFromWebsite.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return logsFromWebsite[row]
    }
}


// MARK: - NSComboBoxDelegate

extension MainVC: NSComboBoxDelegate {
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        UserDefaults.standard.checkerWaitingTime = Double(comboBoxCheckerWaitingTime.stringValue) ?? 5.0
    }
}
