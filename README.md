# E-Commerce Database System

An end-to-end demonstration of systematic database design for an e-commerce platform—beginning with analysis, moving through conceptual modeling, and PostgreSQL implementation.

---

## Table of Contents

1. [Process Overview](#process-overview)  
2. [Step 1: Competitive Site Analysis](#step-1-competitive-site-analysis)  
3. [Step 2: Separate ER Modeling](#step-2-separate-er-modeling)  
4. [Step 3: Layered ER Comparison](#step-3-layered-er-comparison)  
5. [Step 4: Consolidated ER Diagram](#step-4-consolidated-er-diagram)  
6. [Step 5: ER→Relational Mapping](#step-5-errdb-mapping)  
7. [Step 6: Schema Implementation](#step-6-schema-implementation)  
8. [Next Steps & Artifacts](#next-steps--artifacts)  
9. [Project Structure (Placeholder)](#project-structure-placeholder)  

---

## Process Overview

Rather than jumping straight to tables and queries, we followed a disciplined workflow:

1. **Analyze** three major e-commerce sites  
2. **Model** each with its own ER diagram  
3. **Compare** models side by side in layered form  
4. **Merge** insights into one unified ER design  
5. **Map** the final ER diagram to relational tables  
6. **Implement** the schema in PostgreSQL  
7. **Validate** with sample data, integrity checks, and sample queries  

---

## Step 1: Site Analysis

- **Objective:** Understand how Amazon, Hepsiburada, and Trendyol structure their data domains (customers, orders, products, payments, logistics, reviews, etc.).  
- **Approach:**  
  - Walk through each site’s user flows: sign-up, browse, add to cart, checkout, delivery, review.  
  - Note unique features (e.g., “Prime Shipping,” “Premium Membership,” “Influencer Referrals,” wallet vs. card payments).  
  - Capture each platform’s data requirements in a short spec sheet.

## Step 2: Separate ER Modeling

For each platform, we created an independent conceptual model:

- **Amazon ER**  
  ![Amazon ER](Diyagramlar/AMAZON.png)
- **Hepsiburada ER**  
  ![Hepsiburada ER](Diyagramlar/HEPSİBURADA.png)
- **Trendyol ER**  
  ![Trendyol ER](Diyagramlar/TRENDYOL.png)

Each diagram uses three overlaid “layers” (entities, relationships, specializations) to keep complexity manageable.

---

## Step 3: Layered ER Comparison

- **Photoshop File (Blueprint for ER diagrams):**  
  ![Layered ER Comparison](Diyagramlar/Blueprint.png)
- **Goal:** Visually align the three ERDs in layers to spot:  
  - Common entities (User, Customer, Order, Product, Shop)  
  - Divergent relationship patterns (e.g., “Follows” vs. “Refers,” “Lists” vs. “Collections”)  
  - Attribute-level nuances (e.g., wallet vs. transaction vs. coupon).

By toggling layers on and off, we traced each platform’s unique contribution to the overall data model.

---

## Step 4: Consolidated ER Diagram

- **Artifact:** 
  ![Consolidated ER](Diyagramlar/Z%20BİRLEŞMİŞ.png)
- **Outcome:** A single, harmonized ER that incorporates every entity, relationship, and specialization discovered in Steps 2–3.  
- **Highlights:**  
  - Unified customer hierarchy (standard → premium → influencer → affiliate)  
  - Combined payment schema (card, wallet, transaction, coupon)  
  - A single `ShopProduct` bridge capturing sells, reviews, lists/collections, related-to links.

---

## Step 5: ER→RDB Mapping

  [ER → RDB Mapping (DOCX)](ER%20TO%20RDB.docx)
- **Conversion Strategy:**  
  1. **Entities:** each becomes a table with a surrogate primary key.  
  2. **1:N & M:N relationships:** handled via foreign keys and association tables.  
  3. Attributes:** implemented with one-to-one tables for subtype attributes (e.g., `Premium`, `Influencer`, `Affiliate`).  
  4. **N-ary and multi-role relationships:** flattened into dedicated junction tables with composite keys.,
![[Pasted image 20250520005748.png]]

This mapping ensures referential integrity and prepares the schema for PostgreSQL.

---

## Step 6: Schema Implementation

- **DDL Script:**   [Create Tables & Constraints (SQL)](ECOMMCREATETABLESTATEMENTS.sql)
  - Defines tables, primary/foreign keys, uniqueness and check constraints.  
- **Sample Data Dump:**   [Load Sample Data (SQL)](ECOMMdumpfile.sql)
  - Contains structured sample inserts to exercise every table and relationship.  
---

## Next Steps & Artifacts

- **Integrity Checks:** add CHECK constraints and validation scripts.  
- **Triggers & Functions:** implement in `/triggers/`.  
- **Sample Queries:** curate CRUD scenarios and multi-table analytics in `sample queryler/` and `select sqlleri/`.  
- **Documentation:** refine attribute definitions and update this README as the project structure solidifies.

---
## ## Installation

1. Clone the repository:
    
    `git clone https://github.com/SpongeBall-GumPants/E-Commerce-Database-System.git cd E-Commerce-Database-System`
    
2. Set up PostgreSQL Database:
    
	- Create a PostgreSQL database:    
        `createdb data_pipeline_db`
        
    - Update the database connection settings in `config.py`.

--- 
## Contributing

1. Fork the repository.
    
2. Create a new branch (`git checkout -b feature-branch`).
    
3. Make your changes and submit a pull request with a description.
    

---

## License

MIT License
