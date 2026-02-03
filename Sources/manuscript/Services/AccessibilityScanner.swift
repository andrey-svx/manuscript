import Foundation
import ApplicationServices

class AccessibilityScanner {
    
    static func findSimulatorApp(pid: pid_t) -> AXUIElement? {
        return AXUIElementCreateApplication(pid)
    }
    
    static func findActiveSimulatorWindow(app: AXUIElement, candidates: [SimulatorDevice]) -> (AXUIElement, SimulatorDevice)? {
        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)
        guard result == .success, let windows = windowsRef as? [AXUIElement] else { return nil }
        
        for window in windows {
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            guard let title = titleRef as? String else { continue }
            
            for device in candidates {
                if title.contains(device.name) {
                    return (window, device)
                }
            }
        }
        return nil
    }
    
    // MARK: - Search Strategies
    
    static func findElementByID(root: AXUIElement, id: String) -> AXUIElement? {
        var idRef: CFTypeRef?
        AXUIElementCopyAttributeValue(root, kAXIdentifierAttribute as CFString, &idRef)
        if let currentId = idRef as? String, currentId == id {
            if isTextField(root) { return root }
            return findFirstTextField(root: root)
        }
        
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = findElementByID(root: child, id: id) {
                    return found
                }
            }
        }
        return nil
    }
    
    static func findFieldByLabel(root: AXUIElement, label: String) -> AXUIElement? {
        var foundLabel = false
        return scanForLabelAndNextField(root: root, label: label, foundLabel: &foundLabel)
    }
    
    private static func scanForLabelAndNextField(root: AXUIElement, label: String, foundLabel: inout Bool) -> AXUIElement? {
        if !foundLabel {
            if isStaticText(root) {
                if getValueOrDesc(root) == label {
                    foundLabel = true
                }
            }
        } else {
            if isTextField(root) {
                return root
            }
        }
        
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = scanForLabelAndNextField(root: child, label: label, foundLabel: &foundLabel) {
                    return found
                }
            }
        }
        return nil
    }
    
    static func findFieldByPlaceholder(root: AXUIElement, placeholder: String) -> AXUIElement? {
        if isTextField(root) {
            if getValueOrDesc(root) == placeholder {
                return root
            }
        }
        
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = findFieldByPlaceholder(root: child, placeholder: placeholder) {
                    return found
                }
            }
        }
        return nil
    }
    
    static func findFieldByValue(root: AXUIElement, value: String) -> AXUIElement? {
        if isTextField(root) {
            if getValueOrDesc(root) == value {
                return root
            }
        }
        
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = findFieldByValue(root: child, value: value) {
                    return found
                }
            }
        }
        return nil
    }

    // MARK: - Utilities
    
    static func isTextField(_ element: AXUIElement) -> Bool {
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        guard let role = roleRef as? String else { return false }
        return role == kAXTextFieldRole as String || role == kAXTextAreaRole as String
    }
    
    static func isStaticText(_ element: AXUIElement) -> Bool {
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        guard let role = roleRef as? String else { return false }
        return role == kAXStaticTextRole as String
    }
    
    static func getValueOrDesc(_ element: AXUIElement) -> String {
        var valRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valRef)
        if let val = valRef as? String, !val.isEmpty { return val }
        
        var descRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
        if let desc = descRef as? String, !desc.isEmpty { return desc }
        
        return ""
    }
    
    static func findFirstTextField(root: AXUIElement) -> AXUIElement? {
        if isTextField(root) { return root }
        
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(root, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                if let found = findFirstTextField(root: child) { return found }
            }
        }
        return nil
    }
    
    static func enterText(element: AXUIElement, text: String) -> Bool {
        let error = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, text as CFTypeRef)
        return error == .success
    }
    
    static func dumpHierarchy(element: AXUIElement, depth: Int = 0) {
        let indent = String(repeating: "  ", count: depth)
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        let role = (roleRef as? String) ?? "Unknown"
        var idRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXIdentifierAttribute as CFString, &idRef)
        let id = (idRef as? String) ?? ""
        var descRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
        let desc = (descRef as? String) ?? ""
        var valueRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valueRef)
        var value = (valueRef as? String) ?? ""
        if value.count > 20 { value = String(value.prefix(17)) + "..." }
        let idStr = id.isEmpty ? "" : " id='\(ANSI.green)\(id)\(ANSI.reset)'"
        let descStr = desc.isEmpty ? "" : " desc='\(desc)'"
        let valStr = value.isEmpty ? "" : " val='\(value)'"
        print("\(indent)- [\(role)]\(idStr)\(descStr)\(valStr)")
        var childrenRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)
        if result == .success, let children = childrenRef as? [AXUIElement] {
            for child in children {
                dumpHierarchy(element: child, depth: depth + 1)
            }
        }
    }
}
