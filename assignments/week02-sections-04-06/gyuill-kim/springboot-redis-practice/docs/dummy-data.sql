SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO boards (title, content, created_at)
WITH RECURSIVE cte (n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM cte WHERE n < 1000000
)
SELECT
    CONCAT('Title', LPAD(n, 7, '0')) AS title,
    CONCAT('Content', LPAD(n, 7, '0')) AS content,
    TIMESTAMP(
        DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 3650 + 1) DAY)
        + INTERVAL FLOOR(RAND() * 86400) SECOND
    ) AS created_at
FROM cte;
