import Foundation

class ToDoItem: NSObject {
    @objc dynamic var itemId: String = UUID().uuidString
    @objc dynamic var body: String = ""
    @objc dynamic var isDone: Bool = false
    @objc dynamic var timestamp: Date = Date()
    @objc dynamic var strarray: [String] = []
    @objc dynamic var strdict: [String : String] = [:]

    deinit {
        print("freeing ToDoItem")
    }

    static func primaryKey() -> String? {
        return "itemId"
    }
}

enum PropertyType: String {
    // https://nshipster.com/type-encodings/
    case int8 = "c", uint8 = "C", int16 = "s", uint16 = "S"
    case int32 = "i", uint32 = "I", int64 = "q", uint64 = "Q"
    case float = "f", double = "d", bool = "B"
    case string = "@\"NSString\"", date = "@\"NSDate\""
    case array = "@\"NSArray\"", dict = "@\"NSDictionary\""
}

struct ClassInfo {
    let className: String
    let properties: [String : PropertyType]
}

class MyObserver : NSObject {
    let classInfo: ClassInfo
    let target: ToDoItem
    private var context = 0

    init(classInfo: ClassInfo, observe target: ToDoItem) {
        self.classInfo = classInfo
        self.target = target
        super.init()
        for property in classInfo.properties.keys {
            target.addObserver(self, forKeyPath: property, options: [.old, .new], context: &context)
        }
    }

    deinit {
        for property in classInfo.properties.keys {
            target.removeObserver(self, forKeyPath: property, context: &context)
        }
        print("freeing MyObserver")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // This pattern is from https://stackoverflow.com/a/25219216
        guard context == &self.context else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        guard let keyPath = keyPath else { return }
        guard let change = change else { return }
        print("\(keyPath) changed from \(change[.oldKey]!) to \(change[.newKey]!)")
    }
}

struct Experiment {
    static func model<Element: NSObject>(_ type: Element.Type) -> ClassInfo {
        // Mirror API lets us get stored properties of an instance (but not a class?)
        // https://www.swiftbysundell.com/articles/reflection-in-swift/
        // Example of using the Mirror API for JSON encoding:
        // https://github.com/JohnSundell/Wrap/blob/master/Sources/Wrap.swift
        let mirror = Mirror(reflecting: type.init())
        for child in mirror.children {
            if let label = child.label {
                print("\(label) = \(child.value)")
            }
        }

        var propCount: UInt32 = 0
        var properties: [String : PropertyType] = [:]
        if let props = class_copyPropertyList(type, &propCount) {
            for i in 0..<Int(propCount) {
                let propName = String(cString: property_getName(props[i]))
                print("property \(propName):")

                var attrCount: UInt32 = 0
                if let attrs = property_copyAttributeList(props[i], &attrCount) {
                    for j in 0..<Int(attrCount) {
                        let attrName = String(cString: attrs[j].name)
                        let attrValue = String(cString: attrs[j].value)
                        print("    \(attrName): \(attrValue)")

                        if attrName == "T" {
                            if let propType = PropertyType(rawValue: attrValue) {
                                properties[propName] = propType
                            } else {
                                print("*** Unknown type: \(attrValue)")
                            }
                        }
                    }
                    free(attrs)
                }
            }
            free(props)
        }

        let className = String(cString: class_getName(type))
        return ClassInfo(className: className, properties: properties)
    }

    static func run() {
        let info = model(ToDoItem.self)
        print(info)
        let instance = ToDoItem()
        let observer = MyObserver(classInfo: info, observe: instance)
        instance.isDone = true
        instance.body = "hello"
        instance.timestamp = Date()
    }
}
