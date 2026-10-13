// =============================================================================
// MongoDB Analytical Queries – E-Commerce Big Data Pipeline
// Big Data Computing CAT II – Project 1
//
// Run with:  mongosh ecommerce_bigdata < 05_mongodb_queries.js
// =============================================================================

db = db.getSiblingDB("ecommerce_bigdata");

// ─────────────────────────────────────────────────────────────────────────────
// Section A: amazon_reviews queries
// ─────────────────────────────────────────────────────────────────────────────

print("\n═══════════════════════════════════════════════════════════════");
print(" A1. Total Amazon reviews loaded");
print("═══════════════════════════════════════════════════════════════");
printjson({ total_reviews: db.amazon_reviews.countDocuments() });

// ─────────────────────────────────────────────────────────────────────────────
print("\n═══════════════════════════════════════════════════════════════");
print(" A2. Review count and average rating per product (top 10 by count)");
print("═══════════════════════════════════════════════════════════════");
db.amazon_reviews.aggregate([
    {
        $group: {
            _id:            "$asin",
            review_count:   { $sum: 1 },
            avg_rating:     { $avg: "$rating" },
            helpful_votes:  { $sum: "$helpful_vote" }
        }
    },
    { $sort: { review_count: -1 } },
    { $limit: 10 },
    {
        $project: {
            asin:         "$_id",
            review_count: 1,
            avg_rating:   { $round: ["$avg_rating", 2] },
            helpful_votes: 1,
            _id: 0
        }
    }
]).forEach(printjson);

// ─────────────────────────────────────────────────────────────────────────────
print("\n═══════════════════════════════════════════════════════════════");
print(" A3. Rating distribution across all Amazon reviews");
print("═══════════════════════════════════════════════════════════════");
db.amazon_reviews.aggregate([
    { $group: { _id: "$rating", count: { $sum: 1 } } },
    { $sort: { _id: 1 } },
    { $project: { rating: "$_id", count: 1, _id: 0 } }
]).forEach(printjson);

// ─────────────────────────────────────────────────────────────────────────────
print("\n═══════════════════════════════════════════════════════════════");
print(" A4. Verified vs Non-verified purchase count");
print("═══════════════════════════════════════════════════════════════");
db.amazon_reviews.aggregate([
    { $group: { _id: "$verified_purchase", count: { $sum: 1 } } },
    { $project: { verified_purchase: "$_id", count: 1, _id: 0 } }
]).forEach(printjson);

// ─────────────────────────────────────────────────────────────────────────────
print("\n═══════════════════════════════════════════════════════════════");
print(" A5. Top 10 most helpful reviews (by helpful_vote)");
print("═══════════════════════════════════════════════════════════════");
db.amazon_reviews.find(
    { helpful_vote: { $exists: true, $gt: 0 } },
    { asin: 1, rating: 1, title: 1, helpful_vote: 1, _id: 0 }
).sort({ helpful_vote: -1 }).limit(10).forEach(printjson);

// ─────────────────────────────────────────────────────────────────────────────
// Section B: amazon_products queries
// ─────────────────────────────────────────────────────────────────────────────

print("\n═══════════════════════════════════════════════════════════════");
print(" B1. Total Amazon products loaded");
print("═══════════════════════════════════════════════════════════════");
printjson({ total_products: db.amazon_products.countDocuments() });

// ─────────────────────────────────────────────────────────────────────────────
print("\n═══════════════════════════════════════════════════════════════");
print(" B2. Price range statistics");
print("═══════════════════════════════════════════════════════════════");
db.amazon_products.aggregate([
    { $match: { price: { $gt: 0 } } },
    {
        $group: {
            _id:       null,
            min_price: { $min: "$price" },
            max_price: { $max: "$price" },
            avg_price: { $avg: "$price" },
            count:     { $sum: 1 }
        }
    },
    {
        $project: {
            _id: 0,
            min_price: { $round: ["$min_price", 2] },
            max_price: { $round: ["$max_price", 2] },
            avg_price: { $round: ["$avg_price", 2] },
            count: 1
        }
    }
]).forEach(printjson);

// ─────────────────────────────────────────────────────────────────────────────
print("\n═══════════════════════════════════════════════════════════════");
print(" B3. Products with high rating but few reviews (hidden gems, top 10)");
print("═══════════════════════════════════════════════════════════════");
db.amazon_products.find(
    { average_rating: { $gte: 4.5 }, rating_number: { $lt: 50, $gt: 5 } },
    { parent_asin: 1, title: 1, average_rating: 1, rating_number: 1, price: 1, _id: 0 }
).sort({ average_rating: -1 }).limit(10).forEach(printjson);

// ─────────────────────────────────────────────────────────────────────────────
// Section C: olist_orders_enriched queries
// ─────────────────────────────────────────────────────────────────────────────

print("\n═══════════════════════════════════════════════════════════════");
print(" C1. Total enriched Olist orders");
print("═══════════════════════════════════════════════════════════════");
printjson({ total_orders: db.olist_orders_enriched.countDocuments() });

// ─────────────────────────────────────────────────────────────────────────────
print("\n═══════════════════════════════════════════════════════════════");
print(" C2. Revenue by customer state (top 10)");
print("═══════════════════════════════════════════════════════════════");
db.olist_orders_enriched.aggregate([
    { $match: { order_status: "delivered" } },
    {
        $group: {
            _id:           "$customer_state",
            total_revenue: { $sum: "$total_payment" },
            order_count:   { $sum: 1 }
        }
    },
    { $sort: { total_revenue: -1 } },
    { $limit: 10 },
    {
        $project: {
            state:         "$_id",
            total_revenue: { $round: ["$total_revenue", 2] },
            order_count:   1,
            _id: 0
        }
    }
]).forEach(printjson);

// ─────────────────────────────────────────────────────────────────────────────
print("\n═══════════════════════════════════════════════════════════════");
print(" C3. Payment type breakdown by order count and total value");
print("═══════════════════════════════════════════════════════════════");
db.olist_orders_enriched.aggregate([
    { $unwind: "$payments" },
    {
        $group: {
            _id:         "$payments.payment_type",
            order_count: { $sum: 1 },
            total_value: { $sum: "$payments.payment_value" }
        }
    },
    { $sort: { order_count: -1 } },
    {
        $project: {
            payment_type: "$_id",
            order_count:  1,
            total_value:  { $round: ["$total_value", 2] },
            _id: 0
        }
    }
]).forEach(printjson);

// ─────────────────────────────────────────────────────────────────────────────
print("\n═══════════════════════════════════════════════════════════════");
print(" C4. Average review score by customer state");
print("═══════════════════════════════════════════════════════════════");
db.olist_orders_enriched.aggregate([
    { $match: { "review.review_score": { $exists: true, $ne: null } } },
    {
        $group: {
            _id:       "$customer_state",
            avg_score: { $avg: "$review.review_score" },
            count:     { $sum: 1 }
        }
    },
    { $sort: { avg_score: -1 } },
    {
        $project: {
            state:     "$_id",
            avg_score: { $round: ["$avg_score", 2] },
            count:     1,
            _id: 0
        }
    }
]).forEach(printjson);

// ─────────────────────────────────────────────────────────────────────────────
print("\n═══════════════════════════════════════════════════════════════");
print(" C5. Top 10 product categories by revenue (English names)");
print("═══════════════════════════════════════════════════════════════");
db.olist_orders_enriched.aggregate([
    { $unwind: "$items" },
    { $match: { "items.product_category_en": { $exists: true, $ne: null } } },
    {
        $group: {
            _id:         "$items.product_category_en",
            total_revenue: { $sum: "$items.price" },
            item_count:  { $sum: 1 }
        }
    },
    { $sort: { total_revenue: -1 } },
    { $limit: 10 },
    {
        $project: {
            category:      "$_id",
            total_revenue: { $round: ["$total_revenue", 2] },
            item_count:    1,
            _id: 0
        }
    }
]).forEach(printjson);

print("\nAll MongoDB queries complete.");
