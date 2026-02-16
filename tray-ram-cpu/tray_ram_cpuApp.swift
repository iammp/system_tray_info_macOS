//
//  tray_ram_cpuApp.swift
//  tray-ram-cpu
//
//  Created by Mihai on 16.02.2026.
//

import Cocoa
import IOKit

// COMMENTED OUT: Process Info struct (not used when process display is disabled)
/*
struct ProcessInfo {
    let name: String
    let cpuUsage: Double
    let memoryUsage: Double // in MB
}
*/

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var cpuStatusItem: NSStatusItem!
    var ramStatusItem: NSStatusItem!
    var tempStatusItem: NSStatusItem!
    var timer: Timer?
    
    var cpuMenu: NSMenu!
    var ramMenu: NSMenu!
    var tempMenu: NSMenu!
    
    // Store previous CPU ticks for delta calculation
    var previousCPUTicks: [(user: Double, system: Double, nice: Double, idle: Double)] = []
    
    // Add main to properly initialize NSApplication
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock and don't show in Cmd+Tab - run as menu bar only app
        NSApp.setActivationPolicy(.accessory)
        
        // Create Temperature status bar item (leftmost)
        tempStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create RAM status bar item (middle)
        ramStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create CPU status bar item (rightmost)
        cpuStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create separate menus for CPU, RAM, and Temperature
        cpuMenu = NSMenu()
        cpuMenu.delegate = self
        
        ramMenu = NSMenu()
        ramMenu.delegate = self
        
        tempMenu = NSMenu()
        tempMenu.delegate = self
        
        // Add minimal initial items so menu exists
        cpuMenu.addItem(NSMenuItem(title: "Loading...", action: nil, keyEquivalent: ""))
        ramMenu.addItem(NSMenuItem(title: "Loading...", action: nil, keyEquivalent: ""))
        tempMenu.addItem(NSMenuItem(title: "Loading...", action: nil, keyEquivalent: ""))
        
        // Assign menus to status items
        cpuStatusItem.menu = cpuMenu
        ramStatusItem.menu = ramMenu
        tempStatusItem.menu = tempMenu
        
        // Initialize displays
        updateTempDisplay(temp: 0)
        updateRAMDisplay(usage: 0)
        updateCPUDisplay(usage: 0)
        
        // Start monitoring (update every 1 second)
        updateStats()
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateStats), userInfo: nil, repeats: true)
    }
    
    func updateCPUDisplay(usage: Double) {
        guard let button = cpuStatusItem.button else { return }
        
        let attributedString = NSMutableAttributedString()
        
        // CPU Icon (using SF Symbol)
        if let cpuImage = NSImage(systemSymbolName: "cpu", accessibilityDescription: "CPU") {
            let cpuAttachment = NSTextAttachment()
            cpuAttachment.image = cpuImage
            
            // Resize icon to match text height
            let imageSize = NSSize(width: 13, height: 13)
            cpuAttachment.bounds = CGRect(x: 0, y: -2, width: imageSize.width, height: imageSize.height)
            
            attributedString.append(NSAttributedString(attachment: cpuAttachment))
        }
        
        // CPU Percentage (fixed-width format to prevent shifting, left-aligned)
        let cpuText = NSAttributedString(string: String(format: " %-3.0f%%", usage), attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        ])
        attributedString.append(cpuText)
        
        button.attributedTitle = attributedString
    }
    
    func updateRAMDisplay(usage: Double) {
        guard let button = ramStatusItem.button else { return }
        
        let attributedString = NSMutableAttributedString()
        
        // RAM Icon (using SF Symbol - memorychip)
        if let ramImage = NSImage(systemSymbolName: "memorychip", accessibilityDescription: "RAM") {
            let ramAttachment = NSTextAttachment()
            ramAttachment.image = ramImage
            
            let imageSize = NSSize(width: 13, height: 13)
            ramAttachment.bounds = CGRect(x: 0, y: -2, width: imageSize.width, height: imageSize.height)
            
            attributedString.append(NSAttributedString(attachment: ramAttachment))
        }
        
        // RAM Percentage (fixed-width format to prevent shifting, left-aligned)
        let ramText = NSAttributedString(string: String(format: " %-3.0f%%", usage), attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        ])
        attributedString.append(ramText)
        
        button.attributedTitle = attributedString
    }
    
    func updateTempDisplay(temp: Double) {
        guard let button = tempStatusItem.button else { return }
        
        let attributedString = NSMutableAttributedString()
        
        // Temperature Icon (using SF Symbol - thermometer)
        if let tempImage = NSImage(systemSymbolName: "thermometer.medium", accessibilityDescription: "Temperature") {
            let tempAttachment = NSTextAttachment()
            tempAttachment.image = tempImage
            
            let imageSize = NSSize(width: 13, height: 13)
            tempAttachment.bounds = CGRect(x: 0, y: -2, width: imageSize.width, height: imageSize.height)
            
            attributedString.append(NSAttributedString(attachment: tempAttachment))
        }
        
        // Temperature in Celsius (fixed-width format to prevent shifting, left-aligned)
        let tempText = NSAttributedString(string: String(format: " %-3.0f°C", temp), attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        ])
        attributedString.append(tempText)
        
        button.attributedTitle = attributedString
    }
    
    @objc func updateStats() {
        let cpuUsage = getCPUUsage()
        let ramUsage = getRAMUsage()
        let cpuTemp = getCPUTemperature()
        
        updateTempDisplay(temp: cpuTemp)
        updateRAMDisplay(usage: ramUsage)
        updateCPUDisplay(usage: cpuUsage)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Prevent any windows from opening
        return false
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(self)
    }
    
    // COMMENTED OUT: Process display functionality
    /*
    @objc func doNothing() {
        // Empty action to make menu items appear enabled (white) but do nothing when clicked
    }
    
    // MARK: - Menu Building
    func buildCPUMenu() {
        cpuMenu.removeAllItems()
        
        let processes = getTopProcesses()
        
        // Sort by CPU and get top 5
        let topCPU = processes.sorted { $0.cpuUsage > $1.cpuUsage }.prefix(5)
        
        if topCPU.isEmpty {
            let item = NSMenuItem(title: "No processes found", action: nil, keyEquivalent: "")
            item.isEnabled = false
            cpuMenu.addItem(item)
        } else {
            for (index, process) in topCPU.enumerated() {
                let title = String(format: "%d. %@ - %.1f%%", index + 1, process.name, process.cpuUsage)
                let item = NSMenuItem(title: title, action: #selector(doNothing), keyEquivalent: "")
                item.target = self
                cpuMenu.addItem(item)
            }
        }
        
        // Add common menu items
        cpuMenu.addItem(NSMenuItem.separator())
        cpuMenu.addItem(NSMenuItem(title: "Refresh", action: #selector(updateStats), keyEquivalent: "r"))
        cpuMenu.addItem(NSMenuItem.separator())
        cpuMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    func buildRAMMenu() {
        ramMenu.removeAllItems()
        
        let processes = getTopProcesses()
        
        // Sort by Memory and get top 5
        let topRAM = processes.sorted { $0.memoryUsage > $1.memoryUsage }.prefix(5)
        
        if topRAM.isEmpty {
            let item = NSMenuItem(title: "No processes found", action: nil, keyEquivalent: "")
            item.isEnabled = false
            ramMenu.addItem(item)
        } else {
            for (index, process) in topRAM.enumerated() {
                let title = String(format: "%d. %@ - %.1f%%", index + 1, process.name, process.memoryUsage)
                let item = NSMenuItem(title: title, action: #selector(doNothing), keyEquivalent: "")
                item.target = self
                ramMenu.addItem(item)
            }
        }
        
        // Add common menu items
        ramMenu.addItem(NSMenuItem.separator())
        ramMenu.addItem(NSMenuItem(title: "Refresh", action: #selector(updateStats), keyEquivalent: "r"))
        ramMenu.addItem(NSMenuItem.separator())
        ramMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    */
    
    // Simplified menu builders without process lists
    func buildCPUMenu() {
        cpuMenu.removeAllItems()
        cpuMenu.addItem(NSMenuItem(title: "Refresh", action: #selector(updateStats), keyEquivalent: "r"))
        cpuMenu.addItem(NSMenuItem.separator())
        cpuMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    func buildRAMMenu() {
        ramMenu.removeAllItems()
        ramMenu.addItem(NSMenuItem(title: "Refresh", action: #selector(updateStats), keyEquivalent: "r"))
        ramMenu.addItem(NSMenuItem.separator())
        ramMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    // COMMENTED OUT: Temperature display in menu
    /*
    func buildTempMenu() {
        tempMenu.removeAllItems()
        
        let temp = getCPUTemperature()
        
        if temp > 0 {
            let item = NSMenuItem(title: String(format: "CPU Temperature: %.1f°C", temp), action: nil, keyEquivalent: "")
            item.isEnabled = false
            tempMenu.addItem(item)
        } else {
            let item = NSMenuItem(title: "Temperature unavailable", action: nil, keyEquivalent: "")
            item.isEnabled = false
            tempMenu.addItem(item)
        }
        
        // Add common menu items
        tempMenu.addItem(NSMenuItem.separator())
        tempMenu.addItem(NSMenuItem(title: "Refresh", action: #selector(updateStats), keyEquivalent: "r"))
        tempMenu.addItem(NSMenuItem.separator())
        tempMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    */
    
    // Simplified menu builder without temperature display
    func buildTempMenu() {
        tempMenu.removeAllItems()
        tempMenu.addItem(NSMenuItem(title: "Refresh", action: #selector(updateStats), keyEquivalent: "r"))
        tempMenu.addItem(NSMenuItem.separator())
        tempMenu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
    }
    
    // COMMENTED OUT: Process Information
    /*
    // MARK: - Process Information
    func getTopProcesses() -> [ProcessInfo] {
        var processes: [ProcessInfo] = []
        
        do {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/sh")
            task.arguments = ["-c", "ps -Arco pid,comm,%cpu,%mem | head -50"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()
            
            try task.run()
            
            // Read data BEFORE waitUntilExit to avoid deadlock
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            
            guard let output = String(data: data, encoding: .utf8), !output.isEmpty else {
                return processes
            }
            
            let lines = output.components(separatedBy: "\n")
            
            for (index, line) in lines.enumerated() {
                // Skip header line
                if index == 0 { continue }
                
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                guard !trimmedLine.isEmpty else { continue }
                
                // Split by whitespace and filter out empty strings from fixed-width columns
                let parts = trimmedLine.split(separator: " ", omittingEmptySubsequences: true).map { String($0) }
                
                // Format: PID COMM %CPU %MEM — need at least 4 parts
                guard parts.count >= 4 else { continue }
                
                // Last two are %CPU and %MEM
                guard let cpuUsage = Double(parts[parts.count - 2]),
                      let memUsage = Double(parts[parts.count - 1]) else { continue }
                
                // Process name is everything between PID (first) and the last two numbers
                let name = parts[1..<parts.count - 2].joined(separator: " ")
                guard !name.isEmpty else { continue }
                
                processes.append(ProcessInfo(name: name, cpuUsage: cpuUsage, memoryUsage: memUsage))
            }
        } catch {
            // If process execution fails, return empty array silently
        }
        
        return processes
    }
    */
    
    // MARK: - CPU Usage
    func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t!
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCPUs: uint = 0
        
        var totalUsage: Double = 0.0
        
        let mibKeys: [Int32] = [ CTL_HW, HW_NCPU ]
        mibKeys.withUnsafeBufferPointer { mib in
            var sizeOfNumCPUs: size_t = MemoryLayout<uint>.size
            let status = sysctl(UnsafeMutablePointer<Int32>(mutating: mib.baseAddress), 2, &numCPUs, &sizeOfNumCPUs, nil, 0)
            if status != 0 {
                numCPUs = 1
            }
        }
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCpuInfo)
        
        if result == KERN_SUCCESS {
            var currentTicks: [(user: Double, system: Double, nice: Double, idle: Double)] = []
            
            for i in 0..<Int(numCPUs) {
                let cpuLoadInfo = cpuInfo.advanced(by: Int(CPU_STATE_MAX) * i)
                
                let user = Double(cpuLoadInfo[Int(CPU_STATE_USER)])
                let system = Double(cpuLoadInfo[Int(CPU_STATE_SYSTEM)])
                let nice = Double(cpuLoadInfo[Int(CPU_STATE_NICE)])
                let idle = Double(cpuLoadInfo[Int(CPU_STATE_IDLE)])
                
                currentTicks.append((user: user, system: system, nice: nice, idle: idle))
            }
            
            // Compare with previous ticks to get real-time delta usage
            if previousCPUTicks.count == currentTicks.count {
                for i in 0..<currentTicks.count {
                    let userDelta = currentTicks[i].user - previousCPUTicks[i].user
                    let systemDelta = currentTicks[i].system - previousCPUTicks[i].system
                    let niceDelta = currentTicks[i].nice - previousCPUTicks[i].nice
                    let idleDelta = currentTicks[i].idle - previousCPUTicks[i].idle
                    
                    let totalDelta = userDelta + systemDelta + niceDelta + idleDelta
                    
                    if totalDelta > 0 {
                        let usage = ((userDelta + systemDelta + niceDelta) / totalDelta) * 100.0
                        totalUsage += usage
                    }
                }
                totalUsage /= Double(numCPUs)
            }
            
            // Store current ticks for next comparison
            previousCPUTicks = currentTicks
            
            // Deallocate the CPU info
            let cpuInfoSize = vm_size_t(MemoryLayout<integer_t>.stride * Int(numCpuInfo))
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), cpuInfoSize)
        }
        
        return totalUsage
    }
    
    // MARK: - RAM Usage
    func getRAMUsage() -> Double {
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
        guard totalMemory > 0 else { return 0.0 }
        
        var vmStats = vm_statistics64()
        var infoCount = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &infoCount)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = Double(vm_kernel_page_size)
            
            // Memory Used = Total - Free - Cached Files
            // free_count = truly free pages
            // external_page_count = file-backed/cached pages (shown as "Cached Files" in Activity Monitor)
            let freeAndCached = (Double(vmStats.free_count) + Double(vmStats.external_page_count)) * pageSize
            let usedMemory = totalMemory - freeAndCached
            let usagePercentage = (usedMemory / totalMemory) * 100.0
            return usagePercentage
        }
        
        return 0.0
    }
    
    // MARK: - CPU Temperature via SMC
    
    // SMC data types and structures
    struct SMCKeyData {
        struct Vers {
            var major: UInt8 = 0
            var minor: UInt8 = 0
            var build: UInt8 = 0
            var reserved: UInt8 = 0
            var release: UInt16 = 0
        }
        
        struct PLimitData {
            var version: UInt16 = 0
            var length: UInt16 = 0
            var cpuPLimit: UInt32 = 0
            var gpuPLimit: UInt32 = 0
            var memPLimit: UInt32 = 0
        }
        
        struct KeyInfo {
            var dataSize: UInt32 = 0
            var dataType: UInt32 = 0
            var dataAttributes: UInt8 = 0
        }
        
        var key: UInt32 = 0
        var vers = Vers()
        var pLimitData = PLimitData()
        var keyInfo = KeyInfo()
        var result: UInt8 = 0
        var status: UInt8 = 0
        var data8: UInt8 = 0
        var data32: UInt32 = 0
        var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                     UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                     UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                     UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) =
            (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
             0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    }
    
    func fourCharCode(_ string: String) -> UInt32 {
        var result: UInt32 = 0
        for char in string.utf8 {
            result = (result << 8) | UInt32(char)
        }
        return result
    }
    
    func readSMCTemperature() -> Double? {
        var conn: io_connect_t = 0
        
        // Use mach_port_t(0) which is the value of kIOMasterPortDefault/kIOMainPortDefault
        let service = IOServiceGetMatchingService(mach_port_t(0), IOServiceMatching("AppleSMC"))
        guard service != 0 else { return nil }
        
        let result = IOServiceOpen(service, mach_task_self_, 0, &conn)
        IOObjectRelease(service)
        guard result == kIOReturnSuccess else { return nil }
        
        defer { IOServiceClose(conn) }
        
        // Extended list of CPU temperature keys for different Mac models
        // TC0P = CPU 1 Proximity, TC0D/TC0E/TC0F = CPU die temps
        // TC1C/TC2C = CPU cores, TCAD = CPU A/D, TCXC = CPU Core
        let tempKeys = ["TC0P", "TC0D", "TC0E", "TC0F", "TC1C", "TC2C", "TCAD", "TC0c", "TC1c", "TCXC", "TCXc"]
        var temperatures: [Double] = []
        
        for key in tempKeys {
            if let temp = readSMCKey(conn: conn, key: key), temp > 0 && temp < 120 {
                temperatures.append(temp)
            }
        }
        
        guard !temperatures.isEmpty else { return nil }
        
        // Return average of all valid temperature readings
        return temperatures.reduce(0, +) / Double(temperatures.count)
    }
    
    func readSMCKey(conn: io_connect_t, key: String) -> Double? {
        var inputData = SMCKeyData()
        var outputData = SMCKeyData()
        
        inputData.key = fourCharCode(key)
        inputData.data8 = 9 // kSMCGetKeyInfo
        
        var outputSize = MemoryLayout<SMCKeyData>.size
        
        // Get key info
        let result1 = IOConnectCallStructMethod(conn, 2,
                                                 &inputData, MemoryLayout<SMCKeyData>.size,
                                                 &outputData, &outputSize)
        guard result1 == kIOReturnSuccess else { return nil }
        
        // Read the value
        inputData.keyInfo.dataSize = outputData.keyInfo.dataSize
        inputData.data8 = 5 // kSMCReadKey
        
        let result2 = IOConnectCallStructMethod(conn, 2,
                                                 &inputData, MemoryLayout<SMCKeyData>.size,
                                                 &outputData, &outputSize)
        guard result2 == kIOReturnSuccess else { return nil }
        
        // Convert SMC bytes to temperature (sp78 format: signed 7.8 fixed point)
        let integerPart = Double(outputData.bytes.0)
        let fractionalPart = Double(outputData.bytes.1) / 256.0
        let temperature = integerPart + fractionalPart
        
        return temperature
    }
    
    func getCPUTemperature() -> Double {
        // Read directly from SMC hardware sensors
        if let temp = readSMCTemperature() {
            return temp
        }
        
        // Fallback: estimate based on CPU load
        // This is less accurate but better than showing 0
        let cpuUsage = getCPUUsage()
        // Typical range: idle = 40°C, moderate = 60°C, high = 80°C
        let estimatedTemp = 40.0 + (cpuUsage / 100.0) * 40.0
        return estimatedTemp
    }
}

// MARK: - NSMenuDelegate
extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Update menu contents when it's about to open
        if menu == cpuMenu {
            buildCPUMenu()
        } else if menu == ramMenu {
            buildRAMMenu()
        } else if menu == tempMenu {
            buildTempMenu()
        }
    }
}
