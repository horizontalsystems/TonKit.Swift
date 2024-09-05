import BigInt
import GRDB
import TonSwift

extension BigUInt: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        description.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> BigUInt? {
        guard case let DatabaseValue.Storage.string(value) = dbValue.storage else {
            return nil
        }
        return BigUInt(value)
    }
}

extension Address: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        toRaw().databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Address? {
        guard case let DatabaseValue.Storage.string(value) = dbValue.storage else {
            return nil
        }

        do {
            return try Address.parse(raw: value)
        } catch {
            return nil
        }
    }
}

extension Account.Status: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        rawValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Account.Status? {
        guard case let DatabaseValue.Storage.string(value) = dbValue.storage else {
            return nil
        }

        return Account.Status(rawValue: value)
    }
}

extension Jetton.VerificationType: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        rawValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Jetton.VerificationType? {
        guard case let DatabaseValue.Storage.string(value) = dbValue.storage else {
            return nil
        }

        return Jetton.VerificationType(rawValue: value)
    }
}

extension Tag.Platform: DatabaseValueConvertible {
    public var databaseValue: DatabaseValue {
        rawValue.databaseValue
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Tag.Platform? {
        guard case let DatabaseValue.Storage.string(value) = dbValue.storage else {
            return nil
        }

        return Tag.Platform(rawValue: value)
    }
}
