//
//  PrinterDiscoveryService.swift
//  HYPrinter
//
//  Created by Codex on 2026/4/11.
//

import Foundation
import Network

struct PrinterDevice: Codable, Equatable {
    var name: String
    var url: URL
    var isConnected: Bool
    var isManual: Bool
    
    var uniqueKey: String {
        let host = url.host ?? url.absoluteString
        return "\(host.lowercased()):\(url.port ?? -1)"
    }
}

protocol PrinterDiscoveryServiceDelegate: AnyObject {
    func printerDiscoveryService(_ service: PrinterDiscoveryService, didUpdate printers: [PrinterDevice])
    func printerDiscoveryService(_ service: PrinterDiscoveryService, didChangeSearching isSearching: Bool)
    func printerDiscoveryService(_ service: PrinterDiscoveryService, didFail message: String)
}

final class PrinterDiscoveryService: NSObject {
    
    static let shared = PrinterDiscoveryService()
    
    weak var delegate: PrinterDiscoveryServiceDelegate?
    
    private let storageKey = "HYPrinter.cachedPrinters"
    private let serviceTypes = ["_ipp._tcp.", "_printer._tcp.", "_pdl-datastream._tcp."]
    private let searchTimeout: TimeInterval = 10.0
    private var browseDuration: TimeInterval {
        searchTimeout / Double(serviceTypes.count)
    }
    
    private var browser: NetServiceBrowser?
    private var discoveredServices: [NetService] = []
    private var advanceWorkItem: DispatchWorkItem?
    private var currentServiceIndex = 0
    private var pendingFailureMessage: String?
    
    private(set) var printers: [PrinterDevice] = []
    private(set) var isSearching = false
    
    private override init() {
        super.init()
        loadCachedPrinters()
    }
    
    func currentPrinters() -> [PrinterDevice] {
        printers
    }
    
    func startDiscovery() {
        stopDiscovery(notify: false)
        resetConnectionStatus(notify: true)
        
        pendingFailureMessage = nil
        isSearching = true
        currentServiceIndex = 0
        delegate?.printerDiscoveryService(self, didChangeSearching: true)
        browseCurrentServiceType()
    }
    
    func stopDiscovery(notify: Bool) {
        advanceWorkItem?.cancel()
        advanceWorkItem = nil
        
        browser?.delegate = nil
        browser?.stop()
        browser = nil
        
        discoveredServices.forEach {
            $0.delegate = nil
            $0.stop()
        }
        discoveredServices.removeAll()
        
        let wasSearching = isSearching
        isSearching = false
        
        if notify && wasSearching {
            delegate?.printerDiscoveryService(self, didChangeSearching: false)
        }
    }
    
    func resetConnectionStatus(notify: Bool) {
        for index in printers.indices {
            printers[index].isConnected = false
        }
        
        saveCachedPrinters()
        
        if notify {
            delegate?.printerDiscoveryService(self, didUpdate: printers)
        }
    }
    
    func addManualPrinter(name: String) {
        let url = URL(string: "manual://\(UUID().uuidString)") ?? URL(fileURLWithPath: UUID().uuidString)
        let printer = PrinterDevice(
            name: name,
            url: url,
            isConnected: false,
            isManual: true
        )
        addOrUpdate(printer, forceOnline: false)
    }
}

private extension PrinterDiscoveryService {
    
    func browseCurrentServiceType() {
        guard currentServiceIndex < serviceTypes.count else {
            finishDiscovery()
            return
        }
        
        let serviceType = serviceTypes[currentServiceIndex]
        let browser = NetServiceBrowser()
        browser.delegate = self
        self.browser = browser
        browser.searchForServices(ofType: serviceType, inDomain: "local.")
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.advanceToNextServiceType()
        }
        advanceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + browseDuration, execute: workItem)
    }
    
    func advanceToNextServiceType() {
        advanceWorkItem?.cancel()
        advanceWorkItem = nil
        
        browser?.delegate = nil
        browser?.stop()
        browser = nil
        
        currentServiceIndex += 1
        browseCurrentServiceType()
    }
    
    func finishDiscovery() {
        let failureMessage = pendingFailureMessage
        stopDiscovery(notify: false)
        
        if let failureMessage, printers.contains(where: \.isConnected) == false {
            delegate?.printerDiscoveryService(self, didFail: failureMessage)
        }
        delegate?.printerDiscoveryService(self, didChangeSearching: false)
    }
    
    func addOrUpdate(_ printer: PrinterDevice, forceOnline: Bool) {
        var candidate = printer
        if forceOnline {
            candidate.isConnected = true
        }
        
        if let index = printers.firstIndex(where: { $0.uniqueKey == candidate.uniqueKey }) {
            printers[index] = candidate
        } else {
            printers.append(candidate)
        }
        
        saveCachedPrinters()
        delegate?.printerDiscoveryService(self, didUpdate: printers)
    }
    
    func markPrinterOffline(with uniqueKey: String) {
        guard let index = printers.firstIndex(where: { $0.uniqueKey == uniqueKey }) else {
            return
        }
        
        printers[index].isConnected = false
        saveCachedPrinters()
        delegate?.printerDiscoveryService(self, didUpdate: printers)
    }
    
    func saveCachedPrinters() {
        guard let data = try? JSONEncoder().encode(printers) else {
            return
        }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
    
    func loadCachedPrinters() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let cachedPrinters = try? JSONDecoder().decode([PrinterDevice].self, from: data) else {
            return
        }
        
        printers = cachedPrinters.map {
            var printer = $0
            printer.isConnected = false
            return printer
        }
    }
    
    func makePrinterDevice(from service: NetService) -> PrinterDevice? {
        guard let hostName = service.hostName?.trimmingCharacters(in: CharacterSet(charactersIn: ".")),
              hostName.isEmpty == false else {
            return nil
        }
        
        let scheme: String
        switch service.type {
        case "_ipp._tcp.":
            scheme = "ipp"
        case "_pdl-datastream._tcp.":
            scheme = "socket"
        default:
            scheme = "printer"
        }
        
        guard let url = URL(string: "\(scheme)://\(hostName):\(service.port)") else {
            return nil
        }
        
        return PrinterDevice(
            name: service.name,
            url: url,
            isConnected: true,
            isManual: false
        )
    }
    
    func discoveryFailureMessage(from errorDict: [String: NSNumber]) -> String {
        if let code = errorDict[NetService.errorCode]?.intValue,
           code == -72008 {
            return "Please enable Local Network permission before searching again."
        }
        return "Unable to complete printer search on the current network. Please try again later."
    }
}

extension PrinterDiscoveryService: NetServiceBrowserDelegate, NetServiceDelegate {
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        guard discoveredServices.contains(service) == false else {
            return
        }
        
        discoveredServices.append(service)
        service.delegate = self
        service.resolve(withTimeout: 6.0)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        discoveredServices.removeAll { $0 == service }
        if let printer = makePrinterDevice(from: service) {
            markPrinterOffline(with: printer.uniqueKey)
        }
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        pendingFailureMessage = pendingFailureMessage ?? discoveryFailureMessage(from: errorDict)
    }
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let printer = makePrinterDevice(from: sender) else {
            return
        }
        addOrUpdate(printer, forceOnline: true)
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        discoveredServices.removeAll { $0 == sender }
    }
}

@available(iOS 14.0, *)
final class PrinterLocalNetworkAuthorizer: NSObject {
    
    private var browser: NWBrowser?
    private var service: NetService?
    private var completion: ((Bool) -> Void)?
    private var timeoutWorkItem: DispatchWorkItem?
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        cancel()
        self.completion = completion
        
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browser = NWBrowser(for: .bonjour(type: "_what._tcp", domain: nil), using: parameters)
        self.browser = browser
        
        browser.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state {
            case .waiting:
                self.finish(granted: false)
            case .failed:
                self.finish(granted: false)
            default:
                break
            }
        }
        
        let service = NetService(domain: "local.", type: "_lnp._tcp.", name: "HYPrinterLocalNetwork", port: 1100)
        self.service = service
        service.delegate = self
        service.schedule(in: .current, forMode: .common)
        service.publish()
        browser.start(queue: .main)
        
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            self?.finish(granted: false)
        }
        self.timeoutWorkItem = timeoutWorkItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: timeoutWorkItem)
    }
    
    func cancel() {
        finish(granted: false, shouldNotify: false)
    }
    
    private func finish(granted: Bool, shouldNotify: Bool = true) {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        
        browser?.cancel()
        browser = nil
        
        service?.stop()
        service?.delegate = nil
        service = nil
        
        let completion = self.completion
        self.completion = nil
        
        if shouldNotify {
            completion?(granted)
        }
    }
}

@available(iOS 14.0, *)
extension PrinterLocalNetworkAuthorizer: NetServiceDelegate {
    
    func netServiceDidPublish(_ sender: NetService) {
        finish(granted: true)
    }
    
    func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        finish(granted: false)
    }
}
