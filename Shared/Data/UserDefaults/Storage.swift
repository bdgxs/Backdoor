import Foundation

// Renamed to avoid ambiguity with CodableStorage
@propertyWrapper
struct UserDefaultsStorage<Value> {
    typealias Callback = (Value) -> Void
    let key: String
    let defaultValue: Value
    let callback: Callback?
    
    init(key: String, defaultValue: Value, callback: Callback? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.callback = callback
    }
    
    var wrappedValue: Value {
        get {
            if let storedValue = UserDefaults.standard.object(forKey: key) as? Value {
                return storedValue
            }
            return defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            callback?(newValue)
        }
    }
}

// Explicitly named to avoid redeclaration conflicts
@propertyWrapper
public struct CodableUserDefaultsStorage<Value: Codable> {
    public typealias Handler = (String, Value) -> Void
    
    private let key: String
    private let defaultValue: Value
    private var handler: Handler?
    
    public init(key: String, defaultValue: Value, handler: Handler? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.handler = handler
    }
    
    public var wrappedValue: Value {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else {
                return defaultValue
            }
            do {
                return try decoder.decode(Value.self, from: data)
            } catch {
                Logger.shared.log(message: "Decoding \(Value.self) failed. \(error)", type: .error)
                return defaultValue
            }
        }
        
        set {
            do {
                let newData = try encoder.encode(newValue)
                UserDefaults.standard.set(newData, forKey: key)
                handler?(key, newValue)
            } catch {
                Logger.shared.log(message: "Encoding failed: \(error)", type: .error)
            }
        }
    }
}

public let encoder: JSONEncoder = {
    let enc = JSONEncoder()
    enc.dateEncodingStrategy = .iso8601
    return enc
}()

public let decoder: JSONDecoder = {
    let dec = JSONDecoder()
    dec.dateDecodingStrategy = .iso8601
    return dec
}()