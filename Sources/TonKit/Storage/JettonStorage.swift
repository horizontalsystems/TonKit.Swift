import Foundation
import GRDB

class JettonStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool

        try migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("Create jettonBalance") { db in
            try db.create(table: "jettonBalance", body: { t in
                t.primaryKey(JettonBalance.Columns.jettonAddress.name, .text, onConflict: .replace)
                t.column(JettonBalance.Columns.jetton.name, .text).notNull()
                t.column(JettonBalance.Columns.balance.name, .text).notNull()
                t.column(JettonBalance.Columns.walletAddress.name, .text).notNull()
            })
        }

        return migrator
    }
}

extension JettonStorage {
    func jettonBalances() throws -> [JettonBalance] {
        try dbPool.read { db in
            try JettonBalance.fetchAll(db)
        }
    }

    func update(jettonBalances: [JettonBalance]) throws {
        _ = try dbPool.write { db in
            try JettonBalance.deleteAll(db)

            for jettonBalance in jettonBalances {
                try jettonBalance.insert(db)
            }
        }
    }
}
