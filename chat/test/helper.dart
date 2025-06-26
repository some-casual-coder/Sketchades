import 'package:rethink_db_ns/rethink_db_ns.dart';

Future<void> createDB(RethinkDb rdb, Connection connection) async {
  await rdb.dbCreate('test').run(connection).catchError((err) => {});
  await rdb.tableCreate('users').run(connection).catchError((err) => {});
  await rdb.tableCreate('messages').run(connection).catchError((err) => {});
  await rdb.tableCreate('receipts').run(connection).catchError((err) => {});
  await rdb
      .tableCreate('typing_events')
      .run(connection)
      .catchError((err) => {});
}

Future<void> cleanDB(RethinkDb rdb, Connection connection) async {
  await rdb.table('users').delete().run(connection);
  await rdb.table('messages').delete().run(connection);
  await rdb.table('receipts').delete().run(connection);
  await rdb.table('typing_events').delete().run(connection);
}
