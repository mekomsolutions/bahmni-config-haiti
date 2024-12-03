CREATE TABLE temporary_table as (
  WITH IndexedCosts AS (
    SELECT
      Row_Number() OVER (
        ORDER BY
          write_date
      ) ix,
      write_date,
      unit_cost,
      product_id
    FROM
      stock_valuation_layer
  ),
  RangedCosts AS (
    SELECT
      CASE WHEN IC.ix = 1 THEN CAST(
        '1900-01-01' AS timestamp without time zone
      ) ELSE IC.write_date END DateFrom,
      CAST(
        COALESCE(IC2.write_date, now()) AS timestamp without time zone
      ) DateTo,
      IC.unit_cost,
      IC.product_id
    FROM
      IndexedCosts IC
      LEFT JOIN IndexedCosts IC2 ON IC.ix = IC2.ix - 1
  )
  SELECT
    "company"."name" AS "company_name",
    "public"."sale_order_line"."id" AS "id",
    "public"."sale_order_line"."order_id" AS "order_id",
    "order"."date_order" AS "date_order",
    "public"."sale_order_line"."name" AS "name",
    "public"."sale_order_line"."product_uom_qty" AS "product_uom_qty",
    "uom_uom"."name" AS "unit_of_measure",
    "public"."sale_order_line"."price_unit" AS "unit_price",
    "currency"."name" AS "currency_name",
    "price_list"."name" AS "price_list_name",
    "public"."sale_order_line"."qty_to_invoice" AS "qty_to_invoice",
    "public"."sale_order_line"."qty_invoiced" AS "qty_invoiced",
    "public"."sale_order_line"."discount" AS "discount",
    "public"."sale_order_line"."price_reduce" AS "price_reduce",
    "payment_term"."name" AS "payment_term_name",
    "public"."sale_order_line"."qty_delivered" AS "qty_delivered",
    "public"."sale_order_line"."price_reduce_taxinc" AS "price_reduce_taxinc",
    "public"."sale_order_line"."price_total" AS "price_total",
    "public"."sale_order_line"."invoice_status" AS "invoice_status",
    "order"."invoice_status" AS "order_invoice_status",
    "order_partner"."name" AS "partner_name",
    "order_partner"."display_name" AS "partner_display_name",
    "order_partner"."ref" AS "partner_uuid",
    "external_id"."name" AS "product_uuid"
  FROM
    "public"."sale_order_line"
    LEFT JOIN "public"."sale_order" "order" ON "public"."sale_order_line"."order_id" = "order"."id"
    LEFT JOIN "public"."res_partner" "order_partner" ON "public"."sale_order_line"."order_partner_id" = "order_partner"."id"
    LEFT JOIN "public"."uom_uom" "uom_uom" ON "public"."sale_order_line"."product_uom" = "uom_uom"."id"
    LEFT JOIN "public"."res_currency" "currency" ON "public"."sale_order_line"."currency_id" = "currency"."id"
    LEFT JOIN "public"."product_product" "product" ON "public"."sale_order_line"."product_id" = "product"."id"
    LEFT JOIN "public"."ir_model_data" "external_id" ON "public"."sale_order_line"."product_id" = "external_id"."res_id" AND "external_id"."model" = 'product.product' 
    LEFT OUTER JOIN "public"."product_pricelist" "price_list" ON "order"."pricelist_id" = "price_list"."id"
    LEFT OUTER JOIN "public"."res_company" "company" ON "public"."sale_order_line"."company_id" = "company"."id"
    LEFT OUTER JOIN "public"."account_payment_term" "payment_term" ON "order"."payment_term_id" = "payment_term"."id"
    LEFT OUTER JOIN RangedCosts RC ON (product.id = RC.product_id)
    AND (
      "order"."date_order" > RC.DateFrom
    )
    AND (
      "order"."date_order" <= RC.DateTo
    )
  ORDER BY
    "public"."sale_order_line"."id"
)