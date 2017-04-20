WITH
bounds AS (
	SELECT ST_MakeEnvelope(_west, _south, _east, _north, 28992) geom
),
﻿pointcloud AS (
	SELECT PC_FilterEquals(pa,'classification',6) pa
	FROM ahn3_pointcloud.patches, bounds
	WHERE ST_DWithin(geom, PC_envelope(pa) ,10) --patches should be INSIDE bounds
),
footprints AS (
	SELECT ST_Force3D(ST_GeometryN(ST_SimplifyPreserveTopology(geometrie,0.4),1)) geom,
	a.identificatiebagpnd id,
    0 bouwjaar
	FROM imgeo.bgt_pand a, bounds b
	WHERE 1 = 1
	AND ST_Area(a.geometrie) > 5
	AND ST_Intersects(a.geometrie, b.geom)
	AND ST_Intersects(ST_Centroid(a.geometrie), b.geom)
	AND ST_IsValid(a.geometrie)
),
papoints AS ( --get points from intersecting patches
	SELECT
		a.id,
		PC_Explode(b.pa) pt,
		geom footprint
	FROM footprints a
	LEFT JOIN pointcloud b ON PC_Intersects(a.geom, b.pa)
),
stats_fast AS (
	SELECT
		PC_PatchAvg(PC_Union(pa),'z') AS max,
		PC_PatchMin(PC_Union(pa),'z') AS min,
		footprints.id,
		bouwjaar,
		geom footprint
	FROM footprints
	LEFT JOIN pointcloud ON PC_Intersects(geom, pa)
	GROUP BY footprints.id, footprint, bouwjaar
),
polygons AS (
	SELECT
		id, bouwjaar,
		(
			ST_Extrude(
				ST_Translate(footprint,0,0, min - 1) --pull 1 meter down
			, 0,0,max-min -1)
		)
		geom FROM stats_fast
)

SELECT id,
--s.type as type,
'building' as type,
'red' color, ST_AsX3D((p.geom)) geom
FROM polygons p
WHERE p.geom Is Not Null --this can happen with not patch
