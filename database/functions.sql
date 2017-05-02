CREATE OR REPLACE FUNCTION public.st_triangulate2dz(geometry)
  RETURNS geometry AS
'$libdir/postgis-2.3', 'sfcgal_triangulate'
  LANGUAGE c IMMUTABLE STRICT
  COST 100;


---------------------------


CREATE OR REPLACE FUNCTION public.patch_to_geom(
    inpatch pcpatch,
    ingeom geometry)
  RETURNS geometry AS
$BODY$
DECLARE
inpatch pcpatch := inpatch;
ingeom geometry := ingeom;
output geometry;

BEGIN

WITH
papoints AS (
	SELECT PC_Explode(inpatch) pt
),
--Dump geometry as a linestring (ring)
rings AS (
	SELECT (ST_DumpRings(ingeom)).*
),
--Dump the linestring to points (keeping the originating ring path)
edge_points AS (
	SELECT path ringpath, (ST_Dumppoints(rings.geom)).*
	FROM rings
),
--Find the 10 closest points to the vertex
closestpoints AS (
	SELECT a.ringpath, a.path, a.geom,
	unnest(ARRAY(
		SELECT PC_Get(pt,'z') FROM papoints b
		ORDER BY a.geom <#> Geometry(b.pt)
		LIMIT 10
	)) AS z FROM edge_points AS a
)
--Use the avg of the closest points as z
,emptyz AS (
	SELECT
	ringpath, path, geom, avg(z) z
	FROM closestpoints
	GROUP BY ringpath, path, geom
)
-- assign z-value for every boundary point
,filledz AS (
	SELECT ringpath,
	ST_Translate(St_Force3D(emptyz.geom), 0,0,z) geom
	--ST_Translate(St_Force3D(emptyz.geom), 0,0,PC_Get(pt,'z')) geom
	FROM emptyz
)
-- prepare the rings back from the points
,allrings AS (
	SELECT ringpath, ST_AddPoint(ST_MakeLine(geom), First(geom)) geom
	FROM filledz
	GROUP BY ringpath
)
--at least there will be an outer ring
,outerring AS (
	SELECT geom
	FROM allrings
	WHERE ringpath[1] = 0
)
--there may be inner rings
,innerrings AS (
	SELECT St_Accum(allrings.geom) arr
	FROM allrings
	WHERE ringpath[1] > 0
),
--Create tbe polygons back from the rings
polygonz AS (
	SELECT COALESCE(ST_MakePolygon(a.geom, b.arr),ST_MakePolygon(a.geom)) geom
	FROM outerring a, innerrings b
)

SELECT polygonz.geom INTO output FROM polygonz;
RETURN output;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



----------------



CREATE OR REPLACE FUNCTION public.first_agg(
    anyelement,
    anyelement)
  RETURNS anyelement AS
$BODY$
        SELECT $1;
$BODY$
  LANGUAGE sql IMMUTABLE STRICT
  COST 100;


----------------------


CREATE AGGREGATE public.first(anyelement) (
  SFUNC=first_agg,
  STYPE=anyelement
);