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
                t.column(Event.Columns.lt.name, .text).notNull()
                t.column(Event.Columns.timestamp.name, .text).notNull()
                t.column(Event.Columns.isScam.name, .text).notNull()
                t.column(Event.Columns.isProgress.name, .text).notNull()
                t.column(Event.Columns.actions.name, .text).notNull()
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

    func events(tagQueries _: [TagQuery], beforeLt: Int64?, limit: Int) throws -> [Event] {
        try dbPool.read { db in
            var request = Event
                .order(Event.Columns.lt.desc)
                .limit(limit)

            if let beforeLt {
                request = request.filter(Event.Columns.lt < beforeLt)
            }

            return try request.fetchAll(db)
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
}
