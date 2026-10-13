// =============================================================================
// MongoDB Setup – E-Commerce Big Data Pipeline
// Big Data Computing CAT II – Project 1
//
// Run with:  mongosh < 01_setup_collections.js
//            mongosh --file 01_setup_collections.js
// =============================================================================

// ── Database ─────────────────────────────────────────────────────────────────
const DB_NAME = "ecommerce_bigdata";
db = db.getSiblingDB(DB_NAME);
print(`Using database: ${DB_NAME}`);

// ── Drop existing collections (clean re-run) ─────────────────────────────────
["amazon_reviews", "amazon_products", "olist_orders_enriched"].forEach(col => {
    if (db.getCollectionNames().includes(col)) {
        db[col].drop();
        print(`Dropped: ${col}`);
    }
});

// =============================================================================
// Collection 1: amazon_reviews
// Stores Amazon Automotive review documents.
// =============================================================================
db.createCollection("amazon_reviews", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["rating", "asin", "user_id"],
            properties: {
                rating:          { bsonType: ["double", "int"],  description: "Star rating 1-5" },
                title:           { bsonType: "string" },
                text:            { bsonType: "string" },
                asin:            { bsonType: "string",           description: "Amazon product ID" },
                parent_asin:     { bsonType: "string" },
                user_id:         { bsonType: "string" },
                timestamp:       { bsonType: ["long", "date"] },
                helpful_vote:    { bsonType: ["int", "long"] },
                verified_purchase: { bsonType: "bool" }
            }
        }
    },
    validationAction: "warn"    // warn (don't reject) so malformed rows are logged not dropped
});

db.amazon_reviews.createIndex({ asin: 1 });
db.amazon_reviews.createIndex({ rating: 1 });
db.amazon_reviews.createIndex({ user_id: 1 });
db.amazon_reviews.createIndex({ timestamp: -1 });
db.amazon_reviews.createIndex({ asin: 1, rating: 1 });
print("Created collection: amazon_reviews");

// =============================================================================
// Collection 2: amazon_products
// Stores Amazon Automotive product metadata documents.
// =============================================================================
db.createCollection("amazon_products", {
    validator: {
        $jsonSchema: {
            bsonType: "object",
            required: ["parent_asin"],
            properties: {
                parent_asin:  { bsonType: "string" },
                title:        { bsonType: "string" },
                main_category: { bsonType: "string" },
                categories:   { bsonType: "array" },
                price:        { bsonType: ["double", "null"] },
                average_rating: { bsonType: ["double", "null"] },
                rating_number:  { bsonType: ["int", "long", "null"] },
                features:    { bsonType: "array" },
                description: { bsonType: "array" },
                images:      { bsonType: "array" },
                videos:      { bsonType: "array" }
            }
        }
    },
    validationAction: "warn"
});

db.amazon_products.createIndex({ parent_asin: 1 }, { unique: true });
db.amazon_products.createIndex({ main_category: 1 });
db.amazon_products.createIndex({ price: 1 });
db.amazon_products.createIndex({ average_rating: -1 });
print("Created collection: amazon_products");

// =============================================================================
// Collection 3: olist_orders_enriched
// Denormalized Olist order documents (order + items + payment + review).
// Demonstrates joining relational data into document form in MongoDB.
// =============================================================================
db.createCollection("olist_orders_enriched");
db.olist_orders_enriched.createIndex({ order_id: 1 },         { unique: true });
db.olist_orders_enriched.createIndex({ customer_id: 1 });
db.olist_orders_enriched.createIndex({ order_status: 1 });
db.olist_orders_enriched.createIndex({ "items.product_id": 1 });
db.olist_orders_enriched.createIndex({ "items.seller_id": 1 });
db.olist_orders_enriched.createIndex({ "review.review_score": 1 });
db.olist_orders_enriched.createIndex({ order_purchase_timestamp: -1 });
print("Created collection: olist_orders_enriched");

// ── Summary ───────────────────────────────────────────────────────────────────
print("\nCollections in " + DB_NAME + ":");
db.getCollectionNames().forEach(n => print("  " + n));
print("\nMongoDB setup complete.");
