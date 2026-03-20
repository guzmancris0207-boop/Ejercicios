use Northwind

--Ejercicio 1 — Total vendido por cliente

SELECT 
    c.CompanyName,
    SUM(od.UnitPrice * od.Quantity) AS TotalVendido
FROM Customers c
INNER JOIN Orders o ON c.CustomerID = o.CustomerID
INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.CompanyName
ORDER BY TotalVendido DESC;


-- Ejercicio — Ventas 1997 y luego Top 5 CTE WITH

WITH Ventas1997 AS (
    SELECT 
        o.CustomerID,
        SUM(od.UnitPrice * od.Quantity) AS Total
    FROM Orders o
    INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
    WHERE YEAR(o.OrderDate) = 1997
    GROUP BY o.CustomerID
)
SELECT TOP 5 *
FROM Ventas1997
ORDER BY Total DESC;


--Ejercicio — Productos más caros que el promedio de su categoría

SELECT 
    p.ProductName,
    p.UnitPrice,
    p.CategoryID
FROM Products p
WHERE p.UnitPrice > (
    SELECT AVG(p2.UnitPrice)
    FROM Products p2
    WHERE p2.CategoryID = p.CategoryID
);


--Muestra empleados cuya venta total es mayor al promedio de ventas de todos los empleados

SELECT 
    e.FirstName,
    e.LastName,
    SUM(od.UnitPrice * od.Quantity) AS TotalVendido
    FROM Employees e
    INNER JOIN Orders o ON e.EmployeeID = o.EmployeeID
    INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY e.EmployeeID, e.FirstName, e.LastName
    HAVING SUM(od.UnitPrice * od.Quantity) > (
        SELECT AVG(TotalVendido)
        FROM (
            SELECT 
                e2.EmployeeID,
                SUM(od2.UnitPrice * od2.Quantity) AS TotalVendido
            FROM Employees e2
            INNER JOIN Orders o2 ON e2.EmployeeID = o2.EmployeeID
            INNER JOIN [Order Details] od2 ON o2.OrderID = od2.OrderID
            GROUP BY e2.EmployeeID
        ) AS VentasEmpleados
    )

-- Obtén el producto más vendido por cada categoría
WITH VentasPorProducto AS (
    SELECT 
        c.CategoryName,
        p.ProductName,
        SUM(od.Quantity) AS TotalVendido
    FROM [Order Details] od
    INNER JOIN Products p 
        ON od.ProductID = p.ProductID
    INNER JOIN Categories c 
        ON p.CategoryID = c.CategoryID
    GROUP BY 
        c.CategoryName,
        p.ProductName
),
Ranking AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY CategoryName 
            ORDER BY TotalVendido DESC
        ) AS rn
    FROM VentasPorProducto
)

SELECT 
    CategoryName,
    ProductName,
    TotalVendido
FROM Ranking
WHERE rn = 1
ORDER BY CategoryName;


--Ranking de empleados por ventas
SELECT 
    e.FirstName,
    SUM(od.UnitPrice * od.Quantity) AS TotalVentas,
    DENSE_RANK() OVER (
        ORDER BY SUM(od.UnitPrice * od.Quantity) DESC
    ) AS Ranking
FROM Employees e
INNER JOIN Orders o 
    ON e.EmployeeID = o.EmployeeID
INNER JOIN [Order Details] od 
    ON o.OrderID = od.OrderID
GROUP BY e.FirstName;

--Comparar ventas mensuales con el mes anterior
WITH VentasMensuales AS (
    SELECT 
        YEAR(OrderDate) AS Anio,
        MONTH(OrderDate) AS Mes,
        SUM(od.UnitPrice * od.Quantity) AS Total
    FROM Orders o
    INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT *,
    LAG(Total) OVER (ORDER BY Anio, Mes) AS VentaMesAnterior
FROM VentasMensuales;

-- Venta acumulada mensual
WITH VentasMensuales AS (
    SELECT 
        YEAR(OrderDate) AS Anio,
        MONTH(OrderDate) AS Mes,
        SUM(od.UnitPrice * od.Quantity) AS Total
    FROM Orders o
    INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT *,
    SUM(Total) OVER (ORDER BY Anio, Mes) AS Acumulado
FROM VentasMensuales;

-- Ventas por año en columnas
SELECT *
FROM (
    SELECT 
        YEAR(o.OrderDate) AS Anio,
        c.CategoryName,
        od.UnitPrice * od.Quantity AS Venta
    FROM Orders o
    INNER JOIN [Order Details] od ON o.OrderID = od.OrderID
    INNER JOIN Products p ON od.ProductID = p.ProductID
    INNER JOIN Categories c ON p.CategoryID = c.CategoryID
) AS Fuente
PIVOT (
    SUM(Venta)
    FOR Anio IN ([1996], [1997], [1998])
) AS PivotTable;