Drift next step plan

1. Create lib/data/database/app_database.dart.
2. Create an Events table matching EventModel.
3. Resolve the current drift_dev conflict caused by legacy_gantt_chart/sqlite_crdt, then run build_runner.
4. Create EventServiceDrift implements IEventService.
5. Seed data from assets/data/events.json only if the database is empty.
6. Later swap EventServiceJSON to EventServiceDrift in main.dart.
