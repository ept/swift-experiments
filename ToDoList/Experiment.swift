import Foundation

class ToDoItem: NSObject {
    @objc dynamic var itemId: String = UUID().uuidString
    @objc dynamic var body: String = ""
    @objc dynamic var isDone: Bool = false
    var timestamp: Date = Date()

    deinit {
        print("freeing ToDoItem")
    }

    static func primaryKey() -> String? {
        return "itemId"
    }
}

class MyObserver : NSObject {
    let target: ToDoItem
    var observation: NSKeyValueObservation?

    init(observe target: ToDoItem) {
        self.target = target
        super.init()
        observation = target.observe(\.isDone, options: [.old, .new]) {
            _, change in
            print("isDone changed from \(change.oldValue!) to \(change.newValue!)")
        }
    }

    deinit {
        print("freeing MyObserver")
    }
}

struct Experiment {
    static func str(_ cString: UnsafePointer<CChar>?) -> String? {
        if let cString = cString {
            return String(validatingUTF8: cString)
        } else {
            return nil
        }
    }

    static func model<Element: NSObject>(_ type: Element.Type) {
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

        print("type: \(String(cString: class_getName(type)))")
        var propCount: UInt32 = 0
        if let props = class_copyPropertyList(type, &propCount) {
            for i in 0..<Int(propCount) {
                let prop = props[i]
                let name = String(cString: property_getName(prop))
                let attrString = str(property_getAttributes(prop)) ?? ""
                print("property \(name): attr \(attrString)")

                var attrCount: UInt32 = 0
                if let attrs = property_copyAttributeList(prop, &attrCount) {
                    for j in 0..<Int(attrCount) {
                        let attrName = String(cString: attrs[j].name)
                        let attrValue = String(cString: attrs[j].value)
                        print("    attribute \(j): \(attrName) = \(attrValue)")
                    }
                    free(attrs)
                }
            }
            free(props)
        }
        // other functions in runtime.h: object_getIvar, object_setIvar,
        // class_copyProtocolList, class_conformsToProtocol, class_getSuperclass,
        // class_copyMethodList, class_getInstanceMethod,
        // class_copyPropertyList, class_getProperty
    }

    static func run() {
        model(ToDoItem.self)

        let instance = ToDoItem()
        let observer = MyObserver(observe: instance)
        instance.isDone = true
    }
}
