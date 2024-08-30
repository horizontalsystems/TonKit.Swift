import Foundation
import GRDB
import TonSwift

class AccountStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) throws {
        self.dbPool = dbPool

        try migrator.migrate(dbPool)
    }

    var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("Create account") { db in
            try db.create(table: "account", body: { t in
                t.primaryKey(Account.Columns.address.name, .text, onConflict: .replace)
                t.column(Account.Columns.balance.name, .text).notNull()
                t.column(Account.Columns.status.name, .text).notNull()
            })
        }

        return migrator
    }
}

extension AccountStorage {
    func account(address: Address) throws -> Account? {
        try dbPool.read { db in
            try Account.filter(Account.Columns.address == address).fetchOne(db)
        }
    }

    func save(account: Account) throws {
        _ = try dbPool.write { db in
            try account.insert(db)
        }
    }
}
