// =============================================================================
// MongoDB Setup – Tokyo Railway Big Data Pipeline
// Big Data Computing CAT II – Project 2
//
// Run with:  mongosh < 01_setup_collections.js
//            mongosh --file 01_setup_collections.js
// =============================================================================

// ── Database ─────────────────────────────────────────────────────────────────
const DB_NAME = "tokyo_transport";
db = db.getSiblingDB(DB_NAME);
print(`Using database: ${DB_NAME}`);

// ── Drop existing collections (clean re-run) ─────────────────────────────────
["operators", "routes", "stations", "trips", "schedules", "network_stats"].forEach(col => {
    if (db.getCollectionNames().includes(col)) {
        db[col].drop();
        print(`Dropped: ${col}`);
    }
});

// =============================================================================
// Collection 1: operators
// Stores operator metadata for all Tokyo railway operators.
// =============================================================================
db.createCollection("operators", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["agency_id", "name_ja", "name_en", "operator_type", "hdfs_subdir", "url"],
            properties: {
                agency_id:     { bsonType: "string",  description: "Unique operator ID" },
                name_ja:       { bsonType: "string",  description: "Japanese name" },
                name_en:       { bsonType: "string",  description: "English name" },
                operator_type: { bsonType: "string",  enum: ["JR", "Metro", "Private", "Monorail", "Other"], description: "Operator category" },
                hdfs_subdir:   { bsonType: "string",  description: "HDFS data directory" },
                url:           { bsonType: "string",  description: "Operator website URL" }
            }
        }
    },
    validationAction: "warn"
});

db.operators.createIndex({ agency_id: 1 }, { unique: true });
db.operators.createIndex({ operator_type: 1 });
db.operators.createIndex({ name_en: 1 });
db.operators.createIndex({ name_ja: 1 });

// Insert all 20 Tokyo operators
db.operators.insertMany([
    { agency_id: 'tokyu', name_ja: '東急電鉄', name_en: 'Tokyu', operator_type: 'Private', hdfs_subdir: 'private_railway', url: 'https://www.tokyu.co.jp/' },
    { agency_id: 'tokyometro', name_ja: '東京メトロ', name_en: 'Tokyo Metro', operator_type: 'Metro', hdfs_subdir: 'tokyo_metro', url: 'https://www.tokyometro.jp/' },
    { agency_id: 'toei', name_ja: '都営交通', name_en: 'Toei', operator_type: 'Metro', hdfs_subdir: 'toei', url: 'https://www.kotsu.metro.tokyo.jp/' },
    { agency_id: 'jr-east', name_ja: '東日本旅客鉄道', name_en: 'JR East', operator_type: 'JR', hdfs_subdir: 'jr_east', url: 'https://www.jreast.co.jp/' },
    { agency_id: 'tobu', name_ja: '東武鉄道', name_en: 'Tobu', operator_type: 'Private', hdfs_subdir: 'private_railway', url: 'https://www.tobu.co.jp/' },
    { agency_id: 'keio', name_ja: '京王電鉄', name_en: 'Keio', operator_type: 'Private', hdfs_subdir: 'private_railway', url: 'https://www.keio.co.jp/' },
    { agency_id: 'seibu', name_ja: '西武鉄道', name_en: 'Seibu', operator_type: 'Private', hdfs_subdir: 'private_railway', url: 'https://www.seiburailway.jp/' },
    { agency_id: 'odakyu', name_ja: '小田急電鉄', name_en: 'Odakyu', operator_type: 'Private', hdfs_subdir: 'private_railway', url: 'https://www.odakyu.jp/' },
    { agency_id: 'keikyu', name_ja: '京浜急行電鉄', name_en: 'Keikyu', operator_type: 'Private', hdfs_subdir: 'private_railway', url: 'https://www.keikyu.co.jp/' },
    { agency_id: 'keisei', name_ja: '京成電鉄', name_en: 'Keisei', operator_type: 'Private', hdfs_subdir: 'private_railway', url: 'https://www.keisei.co.jp/' },
    { agency_id: 'sotetsu', name_ja: '相模鉄道', name_en: 'Sotetsu', operator_type: 'Private', hdfs_subdir: 'private_railway', url: 'https://www.sotetsu.co.jp/' },
    { agency_id: 'yurikamome', name_ja: 'ゆりかもめ', name_en: 'Yurikamome', operator_type: 'Other', hdfs_subdir: 'private_railway', url: 'https://www.yurikamome.co.jp/' },
    { agency_id: 'tokyomonorail', name_ja: '東京モノレール', name_en: 'Tokyo Monorail', operator_type: 'Monorail', hdfs_subdir: 'private_railway', url: 'https://www.tokyo-monorail.co.jp/' },
    { agency_id: 'twr', name_ja: '東京臨海高速鉄道', name_en: 'TWR', operator_type: 'Other', hdfs_subdir: 'private_railway', url: 'https://www.twr.co.jp/' },
    { agency_id: 'mir', name_ja: '首都圏新都市鉄道', name_en: 'MIR (Tsukuba Express)', operator_type: 'Other', hdfs_subdir: 'private_railway', url: 'https://www.mir.co.jp/' },
    { agency_id: 'sr', name_ja: '埼玉高速鉄道', name_en: 'SR (Saitama Railway)', operator_type: 'Other', hdfs_subdir: 'private_railway', url: 'https://www.s-rail.co.jp/' },
    { agency_id: 'shinkeisei', name_ja: '新京成電鉄', name_en: 'ShinKeisei', operator_type: 'Private', hdfs_subdir: 'private_railway', url: 'https://www.shinkeisei.co.jp/' },
    { agency_id: 'hokuso', name_ja: '北総鉄道', name_en: 'Hokuso', operator_type: 'Private', hdfs_subdir: 'private_railway', url: 'https://www.hokusorailway.co.jp/' },
    { agency_id: 'tamamonorail', name_ja: '多摩都市モノレール', name_en: 'Tama Monorail', operator_type: 'Monorail', hdfs_subdir: 'private_railway', url: 'https://www.tama-monorail.co.jp/' },
    { agency_id: 'minatomirai', name_ja: '横浜高速鉄道', name_en: 'Minatomirai', operator_type: 'Other', hdfs_subdir: 'private_railway', url: 'https://www.mm21railway.co.jp/' }
]);

print("Created collection: operators");

// =============================================================================
// Collection 2: routes
// Stores GTFS routes data for Tokyo railway network.
// =============================================================================
db.createCollection("routes", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["route_id", "agency_id", "route_type"],
            properties: {
                route_id:        { bsonType: "string", description: "Unique route ID" },
                agency_id:       { bsonType: "string", description: "Operator agency ID" },
                route_short_name: { bsonType: "string", description: "Short route name (e.g., 'E01')" },
                route_long_name: { bsonType: "string", description: "Full route name" },
                route_type:      { bsonType: "int",    description: "GTFS route type code" },
                route_color:     { bsonType: "string", description: "Hex color for route on maps" },
                operator_name_en: { bsonType: "string", description: "English operator name" },
                geo:             { bsonType: "object", description: "GeoJSON LineString for route path" }
            }
        }
    },
    validationAction: "warn"
});

db.routes.createIndex({ agency_id: 1, route_id: 1 });
db.routes.createIndex({ route_id: 1 });
db.routes.createIndex({ agency_id: 1 });
db.routes.createIndex({ route_type: 1 });
db.routes.createIndex({ route_short_name: 1 });
db.routes.createIndex({ geo: "2dsphere" });
print("Created collection: routes");

// =============================================================================
// Collection 3: stations
// Stores GTFS stops data for Tokyo railway network.
// =============================================================================
db.createCollection("stations", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["stop_id", "stop_name", "stop_lat", "stop_lon"],
            properties: {
                stop_id:        { bsonType: "string", description: "Unique station ID" },
                stop_name:      { bsonType: "string", description: "Japanese station name" },
                stop_name_en:   { bsonType: "string", description: "English station name" },
                stop_lat:       { bsonType: "double", description: "Latitude" },
                stop_lon:       { bsonType: "double", description: "Longitude" },
                operator_prefix: { bsonType: "string", description: "Prefix for operator-specific IDs" },
                location:       { 
                    bsonType: "object",
                    description: "GeoJSON Point {type:'Point', coordinates:[lon,lat]}"
                },
                wheelchair_accessible: { bsonType: ["int", "bool"], description: "Wheelchair access indicator" },
                zone_id:        { bsonType: "string", description: "Fare zone ID" }
            }
        }
    },
    validationAction: "warn"
});

db.stations.createIndex({ stop_id: 1 });
db.stations.createIndex({ operator_prefix: 1 });
db.stations.createIndex({ stop_name: 1 });
db.stations.createIndex({ location: "2dsphere" });
db.stations.createIndex({ stop_lat: 1, stop_lon: 1 });
print("Created collection: stations");

// =============================================================================
// Collection 4: trips
// Stores GTFS trips data for Tokyo railway network.
// =============================================================================
db.createCollection("trips", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["trip_id", "route_id", "service_id"],
            properties: {
                trip_id:       { bsonType: "string", description: "Unique trip ID" },
                route_id:      { bsonType: "string", description: "Route ID" },
                service_id:    { bsonType: "string", description: "Service calendar ID" },
                trip_headsign: { bsonType: "string", description: "Trip destination sign" },
                direction_id:  { bsonType: "int",    description: "Direction: 0=forward, 1=backward" },
                agency_id:     { bsonType: "string", description: "Operator agency ID" },
                trip_short_name: { bsonType: "string", description: "Short trip name" },
                block_id:      { bsonType: "string", description: "Block assignment ID" },
                shape_id:      { bsonType: "string", description: "Shape reference" }
            }
        }
    },
    validationAction: "warn"
});

db.trips.createIndex({ route_id: 1 });
db.trips.createIndex({ agency_id: 1 });
db.trips.createIndex({ trip_id: 1 });
db.trips.createIndex({ service_id: 1 });
db.trips.createIndex({ route_id: 1, direction_id: 1 });
print("Created collection: trips");

// =============================================================================
// Collection 5: schedules
// Stores GTFS stop_times (sampled/aggregated) for Tokyo railway network.
// =============================================================================
db.createCollection("schedules", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["trip_id", "stop_id", "arrival_time", "departure_time", "stop_sequence"],
            properties: {
                trip_id:         { bsonType: "string", description: "Trip ID" },
                stop_id:         { bsonType: "string", description: "Station stop ID" },
                arrival_time:    { bsonType: "string", description: "Arrival time (HH:MM:SS)" },
                departure_time:  { bsonType: "string", description: "Departure time (HH:MM:SS)" },
                stop_sequence:   { bsonType: "int",    description: "Stop order in trip" },
                agency_id:       { bsonType: "string", description: "Operator agency ID" },
                stop_headsign:   { bsonType: "string", description: "Stop destination sign" },
                timepoint:       { bsonType: ["int", "bool"], description: "Exact time (1) vs estimated (0)" }
            }
        }
    },
    validationAction: "warn"
});

db.schedules.createIndex({ trip_id: 1, stop_sequence: 1 });
db.schedules.createIndex({ trip_id: 1 });
db.schedules.createIndex({ stop_id: 1 });
db.schedules.createIndex({ agency_id: 1 });
db.schedules.createIndex({ stop_id: 1, arrival_time: 1 });
print("Created collection: schedules");

// =============================================================================
// Collection 6: network_stats
// Stores aggregated analytics for Tokyo railway network.
// Populated by PIG/Python post-processing.
// =============================================================================
db.createCollection("network_stats", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["agency_id", "total_routes", "total_trips", "total_stations"],
            properties: {
                agency_id:       { bsonType: "string", description: "Operator agency ID" },
                total_routes:    { bsonType: "int",    description: "Total number of routes" },
                total_trips:     { bsonType: "int",    description: "Total number of trips" },
                total_stations:  { bsonType: "int",    description: "Total number of stations" },
                computed_at:     { bsonType: "date",   description: "Timestamp of computation" },
                updated_at:      { bsonType: "date",   description: "Last update timestamp" },
                trip_frequency:  { bsonType: "double", description: "Average trips per day" },
                station_density: { bsonType: "double", description: "Stations per km²" }
            }
        }
    },
    validationAction: "warn"
});

db.network_stats.createIndex({ agency_id: 1 });
db.network_stats.createIndex({ computed_at: -1 });
db.network_stats.createIndex({ updated_at: -1 });
print("Created collection: network_stats");

// ── Sample aggregation queries to verify setup ───────────────────────────────

print("\n=== Verification: Operator counts by type ===");
var operatorTypeCounts = db.operators.aggregate([
    { $group: { _id: "$operator_type", count: { $sum: 1 } } },
    { $sort: { count: -1 } }
]).toArray();
operatorTypeCounts.forEach(doc => {
    print(`  ${doc._id}: ${doc.count} operators`);
});

print("\n=== Verification: All operator names (English) ===");
var operators = db.operators.find({}, { name_en: 1, operator_type: 1, _id: 0 }).toArray();
operators.forEach(op => print(`  ${op.name_en} (${op.operator_type})`));

// ── Summary ───────────────────────────────────────────────────────────────────
print("\nCollections in " + DB_NAME + ":");
db.getCollectionNames().forEach(n => print("  " + n));

print("\nTokyo transport MongoDB setup complete.");
