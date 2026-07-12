DROP TYPE IF EXISTS is_married;
CREATE TYPE is_married AS ENUM ('M', 'S');

DROP TYPE IF EXISTS sex;
CREATE TYPE sex AS ENUM ('M', 'F', 'O');

DROP SCHEMA IF EXISTS bronze CASCADE;
CREATE SCHEMA bronze;

DROP TABLE IF EXISTS bronze.crm_cust_info;
CREATE TABLE bronze.crm_cust_info (
    cst_id INT,
    cst_key VARCHAR(50),
    cst_firstname VARCHAR(50),
    cst_lastname VARCHAR(50),
    cst_marital_status is_married,
    cst_gndr sex,
    cst_created_date DATE
);

DROP TABLE IF EXISTS bronze.crm_prd_info;
CREATE TABLE bronze.crm_prd_info (
    prd_id INT,
    prd_key VARCHAR(50),
    prd_name VARCHAR(50),
    prd_cost INT,
    prd_line VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE
);

DROP TABLE IF EXISTS bronze.crm_sales_details;
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num VARCHAR(50),
    sls_prd_key VARCHAR(50),
    sls_customer_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT
);

DROP TABLE IF EXISTS bronze.erp_az12;
CREATE TABLE bronze.erp_az12 (
    cid VARCHAR(50),
    bdate DATE,
    gen VARCHAR(10)
);

DROP TABLE IF EXISTS bronze.erp_loc_a101;
CREATE TABLE bronze.erp_loc_a101 (
    cid VARCHAR(50),
    country VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id VARCHAR(50),
    cat VARCHAR(50),
    subcat VARCHAR(50),
    maintenance VARCHAR(5) CHECK (maintenance IN ('Yes', 'No'))
);
