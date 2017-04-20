WITH
bounds AS (
	SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
),
mainroads AS (
	SELECT 'road'::text AS class, a.bgt_functie as type, ST_Intersection(a.geometrie,c.geom) geom
	FROM imgeo.bgt_wegdeel a
	LEFT JOIN imgeo.bgt_overbruggingsdeel b
	ON (St_Intersects((a.geometrie), (b.geometrie)) AND St_Contains(ST_buffer((b.geometrie),1), (a.geometrie)))
	,bounds c
	WHERE a.relatieveHoogteligging = 0
	AND ST_CurveToLine(b.geometrie) Is Null
	AND a.eindregistratie Is Null
	AND b.eindregistratie Is Null
	AND ST_Intersects(geom, a.geometrie)
),
auxroads AS (
	SELECT 'road'::text AS class, bgt_functie as type, ST_Intersection(geometrie,geom) geom
	FROM imgeo.bgt_ondersteunendwegdeel, bounds
	WHERE relatieveHoogteligging = 0
	AND eindregistratie Is Null
	AND ST_Intersects(geom, geometrie)
),
tunnels AS (
	SELECT 'road'::text AS class, 'tunnel'::text as type, ST_Intersection(geometrie,geom) geom
	FROM imgeo.bgt_tunneldeel, bounds
	WHERE eindregistratie Is Null
	AND ST_Intersects(geom, geometrie)
),
pointcloud_ground AS (
	SELECT PC_FilterEquals(pa,'classification',2) pa
	FROM ahn3_pointcloud.patches, bounds
	WHERE PC_Intersects(geom, pa)
),
polygons AS (
	SELECT nextval('counter') id, type, class,(ST_Dump(geom)).geom
	FROM mainroads
	UNION ALL
	SELECT nextval('counter') id, type, class,(ST_Dump(geom)).geom
	FROM auxroads
	UNION ALL
	SELECT nextval('counter') id, type, class,(ST_Dump(geom)).geom
	FROM tunnels
)
,polygonsz AS (
	SELECT id, type, class, patch_to_geom(PC_Union(b.pa), geom) geom
	FROM polygons a
	LEFT JOIN pointcloud_ground b
	ON PC_Intersects(geom, b.pa)
	WHERE ST_GeometryType(geom) = 'ST_Polygon'
	GROUP BY id, type, class, geom
)
,basepoints AS (
	SELECT id,geom FROM polygonsz
	WHERE ST_IsValid(geom)
)
,triangles AS (
	SELECT
		id,
		ST_MakePolygon(
			ST_ExteriorRing(
				(ST_Dump(ST_Triangulate2DZ(ST_Collect(a.geom)))).geom
			)
		)geom
	FROM basepoints a
	GROUP BY id
)
,assign_triags AS (
	SELECT 	a.*, b.type, b.class
	FROM triangles a
	INNER JOIN polygons b
	ON ST_Contains(b.geom, a.geom)
	,bounds c
	WHERE ST_Intersects(ST_Centroid(b.geom), c.geom)
	AND a.id = b.id
)

SELECT _south::text || _west::text || p.id as id, p.type as type,
	ST_AsX3D(ST_Collect(p.geom),5) geom
FROM assign_triags p
GROUP BY p.id, p.type