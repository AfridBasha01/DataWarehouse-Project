-- Check for nulls or duplicates in Primary Key
-- Expectation: No Result
SELECT 
    cst_id,
    COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

/*

SELECT *,
    ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
FROM bronze.crm_cust_info
WHERE cst_id = 29466;

SELECT * FROM(
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
)t
WHERE flag_last != 1;

SELECT * FROM(
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
)t
WHERE flag_last = 1;

*/

-- check for unwanted spaces
-- Expectation: No result
SELECT cst_firstname FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Data Standardization and consistency
SELECT DISTINCT cst_gndr FROM bronze.crm_cust_info;
SELECT DISTINCT cst_marital_status FROM bronze.crm_cust_info;

-- Inserting clean data into silver layer
TRUNCATE TABLE silver.crm_cust_info;
INSERT INTO silver.crm_cust_info (
    cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_marital_status,
    cst_gndr,
    cst_create_date
)
SELECT 
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END AS cst_marital_status,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS cst_gndr,
    cst_create_date
FROM(
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
)t
WHERE flag_last = 1;


-- Check for nulls or duplicates in Primary Key
-- Expectation: No Result
SELECT 
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- check for unwanted spaces
-- Expectation: No result
SELECT cst_firstname FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname FROM silver.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

-- Data Standardization and consistency
SELECT DISTINCT cst_gndr FROM silver.crm_cust_info;
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;

SELECT * FROM silver.crm_cust_info LIMIT 10;

--------------------------
-- bronze.crm_prd_info
--------------------------

-- Check for nulls 
-- Expectation: No Result
SELECT *
FROM bronze.crm_prd_info
WHERE prd_key IS NULL;

-- check for unwanted spaces
-- Expectation: No result
SELECT prd_nm FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- check for nulls or negative numbers
SELECT prd_cost FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization and consistency
SELECT DISTINCT prd_line FROM bronze.crm_prd_info;

SELECT DISTINCT id FROM bronze.erp_px_cat_g1v2
WHERE id NOT IN (SELECT REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_') FROM bronze.crm_prd_info);

SELECT DISTINCT sls_prd_key FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN (SELECT SUBSTRING(prd_key FROM 7 FOR LENGTH(prd_key)) FROM bronze.crm_prd_info);

-- check for invalid date order
SELECT * FROM bronze.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

TRUNCATE TABLE silver.crm_prd_info;
INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    prd_id,
    REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_') AS cat_id,
    SUBSTRING(prd_key FROM 7 FOR LENGTH(prd_key)) AS prd_key,
    prd_nm,
    COALESCE(prd_cost, 0) AS prd_cost,
    CASE UPPER(TRIM(prd_line))
        WHEN 'M' THEN 'Mountain'
        WHEN 'R' THEN 'Road'
        WHEN 'S' THEN 'Other Sales'
        WHEN 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    prd_start_dt,
    LEAD(prd_start_dt) OVER(PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS prd_end_dt
FROM bronze.crm_prd_info

-- Check for nulls 
-- Expectation: No Result
SELECT *
FROM silver.crm_prd_info
WHERE prd_key IS NULL;

-- check for unwanted spaces
-- Expectation: No result
SELECT prd_nm FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- check for nulls or negative numbers
SELECT prd_cost FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- Data Standardization and consistency
SELECT DISTINCT prd_line FROM silver.crm_prd_info;

-- check for invalid date order
SELECT * FROM silver.crm_prd_info
WHERE prd_start_dt > prd_end_dt;

SELECT * FROM silver.crm_prd_info LIMIT 10;

-----------------------
-- crm_sales_details
-----------------------

SELECT * FROM bronze.crm_sales_details LIMIT 10;

SELECT * FROM bronze.crm_sales_details
WHERE sls_ord_num != TRIM(sls_ord_num)

SELECT * FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN(SELECT cst_id FROM bronze.crm_cust_info);

SELECT * FROM bronze.crm_sales_details
WHERE sls_cust_id NOT IN(SELECT cst_id FROM silver.crm_cust_info);

SELECT * FROM bronze.crm_sales_details
WHERE sls_prd_key NOT IN(SELECT prd_key FROM silver.crm_prd_info);

-- Check for invalid Dates
SELECT sls_order_dt FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 OR sls_order_dt IS NULL;

SELECT
    CASE
        WHEN sls_order_dt = 0 THEN NULL
        ELSE sls_order_dt
    END AS sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0
   OR LENGTH(sls_order_dt::text) != 8
   OR sls_order_dt > 20500101
   OR sls_order_dt < 19000101;

-- Check for invalid date orders
SELECT * FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

SELECT 
    sls_sales,
    sls_quantity,
    sls_price
FROM bronze.crm_sales_details 
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL 
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales NULLS FIRST, sls_quantity NULLS FIRST, sls_price NULLS FIRST;

SELECT DISTINCT
    sls_sales AS old_sls_sales,
    sls_quantity,
    sls_price AS old_sls_price,
    CASE
        WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    CASE
        WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details
WHERE sls_sales <> sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY
    sls_sales NULLS FIRST,
    sls_quantity NULLS FIRST,
    sls_price NULLS FIRST;


TRUNCATE TABLE silver.crm_sales_details;
INSERT INTO silver.crm_sales_details (
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    CASE
        WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::text) != 8 THEN NULL
        ELSE TO_DATE(sls_order_dt::text, 'YYYYMMDD')
    END AS sls_order_dt,
    CASE
        WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::text) != 8 THEN NULL
        ELSE TO_DATE(sls_ship_dt::text, 'YYYYMMDD')
    END AS sls_ship_dt,
    CASE
        WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::text) != 8 THEN NULL
        ELSE TO_DATE(sls_due_dt::text, 'YYYYMMDD')
    END AS sls_due_dt,
    CASE
        WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales <> sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
        ELSE sls_sales
    END AS sls_sales,
    sls_quantity,
    CASE
        WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze.crm_sales_details;

-- Check for invalid date orders
SELECT * FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

SELECT 
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details 
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL 
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales NULLS FIRST, sls_quantity NULLS FIRST, sls_price NULLS FIRST;

SELECT * FROM silver.crm_sales_details LIMIT 10;

-----------------------
-- erp_cust_az12
-----------------------

SELECT * FROM bronze.erp_cust_az12;

SELECT * FROM bronze.erp_cust_az12
WHERE CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4 FOR LENGTH(cid))
        ELSE cid 
    END NOT IN (SELECT cst_key FROM silver.crm_cust_info);

SELECT bdate FROM bronze.erp_cust_az12
WHERE bdate < TO_DATE('1924-01-01', 'YYYY-MM-DD') OR bdate > NOW()
ORDER BY bdate;

SELECT DISTINCT gen FROM bronze.erp_cust_az12;


INSERT INTO silver.erp_cust_az12 (cid, bdate, gen)
SELECT 
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4 FOR LENGTH(cid))
        ELSE cid 
    END AS cid,
    CASE
        WHEN bdate > NOW() THEN NULL
        ELSE bdate
    END AS bdate,
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen
FROM bronze.erp_cust_az12;


----------------------
-- erp_loc_a101
----------------------
SELECT * FROM bronze.erp_loc_a101
WHERE REPLACE(cid,'-','') NOT IN(SELECT cst_key FROM silver.crm_cust_info);

SELECT DISTINCT cntry FROM bronze.erp_loc_a101;

SELECT cntry FROM bronze.erp_loc_a101
WHERE cntry IS NULL OR TRIM(cntry) != cntry;

SELECT DISTINCT
    cntry AS old_cntry,
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry
FROM bronze.erp_loc_a101;

INSERT INTO silver.erp_loc_a101 (cid, cntry)
SELECT 
    REPLACE(cid,'-','') AS cid,
    CASE
        WHEN TRIM(cntry) = 'DE' THEN 'Germany'
        WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
        WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry
FROM bronze.erp_loc_a101;

SELECT * FROM silver.erp_loc_a101 LIMIT 10;

------------------------
-- erp_px_cat_g1v2
------------------------
SELECT id FROM bronze.erp_px_cat_g1v2
WHERE TRIM(id) != id;

SELECT * FROM bronze.erp_px_cat_g1v2
WHERE id NOT IN (SELECT cat_id FROM silver.crm_prd_info);

SELECT cat FROM bronze.erp_px_cat_g1v2
WHERE TRIM(cat) != cat;

SELECT subcat FROM bronze.erp_px_cat_g1v2
WHERE TRIM(subcat) != subcat;

SELECT maintenance FROM bronze.erp_px_cat_g1v2
WHERE TRIM(maintenance) != maintenance;

SELECT DISTINCT maintenance FROM bronze.erp_px_cat_g1v2;

INSERT INTO silver.erp_px_cat_g1v2(id, cat, subcat, maintenance)
SELECT 
    id,
    cat,
    subcat,
    maintenance
FROM bronze.erp_px_cat_g1v2;

SELECT * FROM silver.erp_px_cat_g1v2 LIMIT 10;