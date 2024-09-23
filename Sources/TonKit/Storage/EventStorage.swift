import Foundation
import GRDB
import TonSwift

class EventStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool

        try migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("Create eventSyncState") { db in
            try db.create(table: "eventSyncState", body: { t in
                t.primaryKey(EventSyncState.Columns.id.name, .text, onConflict: .replace)
                t.column(EventSyncState.Columns.allSynced.name, .boolean).notNull()
            })
        }

        migrator.registerMigration("Create event") { db in
            try db.create(table: "event", body: { t in
                t.primaryKey(Event.Columns.id.name, .text, onConflict: .replace)
                t.column(Event.Columns.lt.name, .integer).notNull()
                t.column(Event.Columns.timestamp.name, .integer).notNull()
                t.column(Event.Columns.isScam.name, .boolean).notNull()
                t.column(Event.Columns.isProgress.name, .boolean).notNull()
                t.column(Event.Columns.extra.name, .integer).notNull()
                t.column(Event.Columns.actions.name, .text).notNull()
            })
        }

        migrator.registerMigration("Create tag") { db in
            try db.create(table: "tag", body: { t in
                t.column(Tag.Columns.eventId.name, .text).notNull()
                t.column(Tag.Columns.type.name, .text)
                t.column(Tag.Columns.platform.name, .text)
                t.column(Tag.Columns.jettonAddress.name, .text)
                t.column(Tag.Columns.addresses.name, .text).notNull()
            })
        }

        return migrator
    }
}

extension EventStorage {
    func eventSyncState() throws -> EventSyncState? {
        try dbPool.read { db in
            try EventSyncState.fetchOne(db)
        }
    }

    func events(tagQuery: TagQuery, beforeLt: Int64?, limit: Int) throws -> [Event] {
        try dbPool.read { db in
            var arguments = [DatabaseValueConvertible]()
            var whereConditions = [String]()
            var joinClause = ""

            if !tagQuery.isEmpty {
                if let type = tagQuery.type {
                    whereConditions.append("tag.'\(Tag.Columns.type.name)' = ?")
                    arguments.append(type.rawValue)
                }
                if let platform = tagQuery.platform {
                    whereConditions.append("tag.'\(Tag.Columns.platform.name)' = ?")
                    arguments.append(platform.rawValue)
                }
                if let jettonAddress = tagQuery.jettonAddress {
                    whereConditions.append("tag.'\(Tag.Columns.jettonAddress.name)' = ?")
                    arguments.append(jettonAddress)
                }
                if let address = tagQuery.address {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .sortedKeys

                    do {
                        let addressData = try encoder.encode(address)
                        if let addressJson = String(data: addressData, encoding: .utf8) {
                            whereConditions.append("LOWER(tag.'\(Tag.Columns.addresses.name)') LIKE ?")
                            arguments.append("%" + addressJson + "%")
                        }
                    } catch {}
                }

                joinClause = "INNER JOIN tag ON event.\(Event.Columns.id.name) = tag.\(Tag.Columns.eventId.name)"
            }

            if let beforeLt {
                whereConditions.append("event.\(Event.Columns.lt.name) < ?")
                arguments.append(beforeLt)
            }

            let limitClause = "LIMIT \(limit)"
            let orderClause = "ORDER BY event.\(Event.Columns.lt.name) DESC"
            let whereClause = whereConditions.count > 0 ? "WHERE \(whereConditions.joined(separator: " AND "))" : ""

            let sql = """
            SELECT DISTINCT event.*
            FROM event
            \(joinClause)
            \(whereClause)
            \(orderClause)
            \(limitClause)
            """

            let rows = try Row.fetchAll(db.makeStatement(sql: sql), arguments: StatementArguments(arguments))
            return try rows.map { row -> Event in
                try Event(row: row)
            }
        }
    }

    func event(id: String) throws -> Event? {
        try dbPool.read { db in
            try Event
                .filter(Event.Columns.id == id)
                .fetchOne(db)
        }
    }

    func events(ids: [String]) throws -> [Event] {
        try dbPool.read { db in
            try Event
                .filter(ids.contains(Event.Columns.id))
                .fetchAll(db)
        }
    }

    func latestEvent() throws -> Event? {
        try dbPool.read { db in
            try Event
                .order(Event.Columns.lt.desc)
                .limit(1)
                .fetchOne(db)
        }
    }

    func oldestEvent() throws -> Event? {
        try dbPool.read { db in
            try Event
                .order(Event.Columns.lt.asc)
                .limit(1)
                .fetchOne(db)
        }
    }

    func tagTokens() throws -> [TagToken] {
        try dbPool.write { db in
            let request = Tag
                .filter(Tag.Columns.platform != nil)
                .select(Tag.Columns.platform, Tag.Columns.jettonAddress)
                .distinct()
            let rows = try Row.fetchAll(db, request)

            return rows.compactMap { row in
                TagToken(platform: row[0], jettonAddress: row[1])
            }
        }
    }

    func save(eventSyncState: EventSyncState) throws {
        _ = try dbPool.write { db in
            try eventSyncState.insert(db)
        }
    }

    func save(events: [Event]) throws {
        _ = try dbPool.write { db in
            for event in events {
                try event.insert(db)
            }
        }
    }

    func resave(tags: [Tag], eventIds: [String]) throws {
        _ = try dbPool.write { db in
            try Tag.filter(eventIds.contains(Tag.Columns.eventId)).deleteAll(db)

            for tag in tags {
                try tag.insert(db)
            }
        }
    }
}
