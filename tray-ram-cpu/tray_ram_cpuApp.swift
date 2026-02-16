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
        
        // Create CPU status bar item
        cpuStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create RAM status bar item
        ramStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create Temperature status bar item
        tempStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
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
        updateCPUDisplay(usage: 0)
        updateRAMDisplay(usage: 0)
        updateTempDisplay(temp: 0)
        
        // Start monitoring (update every 2 seconds, you can change this to 1 second if preferred)
        updateStats()
        timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(updateStats), userInfo: nil, repeats: true)
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
        
        // CPU Percentage
        let cpuText = NSAttributedString(string: String(format: " %.0f%%", usage), attributes: [
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
        
        // RAM Percentage
        let ramText = NSAttributedString(string: String(format: " %.0f%%", usage), attributes: [
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
        
        // Temperature in Celsius
        let tempText = NSAttributedString(string: String(format: " %.0f°C", temp), attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        ])
        attributedString.append(tempText)
        
        button.attributedTitle = attributedString
    }
    
    @objc func updateStats() {
        let cpuUsage = getCPUUsage()
        let ramUsage = getRAMUsage()
        let cpuTemp = getCPUTemperature()
        
        updateCPUDisplay(usage: cpuUsage)
        updateRAMDisplay(usage: ramUsage)
        updateTempDisplay(temp: cpuTemp)
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
        let prevCpuInfo: processor_info_array_t? = nil
        var numCpuInfo: mach_msg_type_number_t = 0
        let numPrevCpuInfo: mach_msg_type_number_t = 0
        var numCPUs: uint = 0
        let CPUUsageLock: NSLock = NSLock()
        
        var totalUsage: Double = 0.0
        
        let mibKeys: [Int32] = [ CTL_HW, HW_NCPU ]
        mibKeys.withUnsafeBufferPointer { mib in
            var sizeOfNumCPUs: size_t = MemoryLayout<uint>.size
            let status = sysctl(UnsafeMutablePointer<Int32>(mutating: mib.baseAddress), 2, &numCPUs, &sizeOfNumCPUs, nil, 0)
            if status != 0 {
                numCPUs = 1
            }
        }
        
        CPUUsageLock.lock()
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCpuInfo)
        
        if result == KERN_SUCCESS {
            for i in 0..<Int(numCPUs) {
                let cpuLoadInfo = cpuInfo.advanced(by: Int(CPU_STATE_MAX) * i)
                
                let user = Double(cpuLoadInfo[Int(CPU_STATE_USER)])
                let system = Double(cpuLoadInfo[Int(CPU_STATE_SYSTEM)])
                let nice = Double(cpuLoadInfo[Int(CPU_STATE_NICE)])
                let idle = Double(cpuLoadInfo[Int(CPU_STATE_IDLE)])
                
                let total = user + system + nice + idle
                
                if total > 0 {
                    let usage = ((user + system + nice) / total) * 100.0
                    totalUsage += usage
                }
            }
            
            totalUsage /= Double(numCPUs)
        }
        
        if let prevCpuInfo = prevCpuInfo {
            let prevCpuInfoSize: size_t = MemoryLayout<integer_t>.stride * Int(numPrevCpuInfo)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevCpuInfo), vm_size_t(prevCpuInfoSize))
        }
        
        CPUUsageLock.unlock()
        
        return totalUsage
    }
    
    // MARK: - RAM Usage
    func getRAMUsage() -> Double {
        var vmStats = vm_statistics64()
        var infoCount = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &infoCount)
            }
        }
        
        if result == KERN_SUCCESS {
            let pageSize = vm_kernel_page_size
            
            // Calculate used memory
            let usedPages = Int64(vmStats.active_count) +
                           Int64(vmStats.inactive_count) +
                           Int64(vmStats.wire_count)
            
            let usedMemory = Double(usedPages) * Double(pageSize)
            
            // Get total memory
            var size = mach_msg_type_number_t(MemoryLayout<host_basic_info>.size / MemoryLayout<integer_t>.size)
            var hostInfo = host_basic_info()
            
            let hostInfoResult = withUnsafeMutablePointer(to: &hostInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                    host_info(mach_host_self(), HOST_BASIC_INFO, $0, &size)
                }
            }
            
            if hostInfoResult == KERN_SUCCESS {
                let totalMemory = Double(hostInfo.max_mem)
                let usagePercentage = (usedMemory / totalMemory) * 100.0
                return usagePercentage
            }
        }
        
        return 0.0
    }
    
    // MARK: - CPU Temperature
    func getCPUTemperature() -> Double {
        // Try to read from IOKit thermal sensors
        // This reads the thermal state which gives us a relative temperature indicator
        var temperature: Double = 0.0
        
        // Method 1: Try powermetrics (most accurate but may require permissions)
        if let temp = getTempFromPowermetrics() {
            return temp
        }
        
        // Method 2: Estimate based on CPU usage (fallback)
        let cpuUsage = getCPUUsage()
        // Estimate: idle ~45°C, full load ~85°C
        temperature = 45.0 + (cpuUsage / 100.0) * 40.0
        
        return temperature
    }
    
    func getTempFromPowermetrics() -> Double? {
        do {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/powermetrics")
            task.arguments = ["--samplers", "smc", "-i1", "-n1"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()
            
            try task.run()
            
            // Set timeout
            let timeoutDate = Date().addingTimeInterval(1.5)
            while task.isRunning && Date() < timeoutDate {
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            if task.isRunning {
                task.terminate()
            }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            
            guard let output = String(data: data, encoding: .utf8) else {
                return nil
            }
            
            // Parse temperature from powermetrics output
            // Look for lines like "CPU die temperature: 45.2 C"
            var temperatures: [Double] = []
            let lines = output.components(separatedBy: "\n")
            
            for line in lines {
                if line.contains("temperature") && line.contains("C") {
                    // Extract number before "C"
                    let components = line.components(separatedBy: .whitespaces)
                    for (index, component) in components.enumerated() {
                        if component.lowercased() == "c" && index > 0 {
                            if let temp = Double(components[index - 1]) {
                                temperatures.append(temp)
                            }
                        }
                    }
                }
            }
            
            // Return average temperature if found
            if !temperatures.isEmpty {
                return temperatures.reduce(0, +) / Double(temperatures.count)
            }
            
            return nil
            
        } catch {
            return nil
        }
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
