WITH
bounds AS (
  SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
),
pointcloud_water AS (
  SELECT PC_FilterEquals(pa,'classification',9) pa
  FROM adam_pointcloud.patches, bounds
  WHERE PC_Intersects(geom, pa)
),
polygons AS (
  SELECT nextval('counter') id, bgt_type as type, 'water'::text AS class,
    (ST_Dump(ST_Union(
     a.geometrie -- doing intersection later so we can find better average height
    ))).geom
  FROM imgeo.bgt_waterdeel a, bounds b
  WHERE ST_Intersects(a.geometrie, b.geom)
  GROUP BY bgt_type
)
,polygonsz AS (
  SELECT a.id, a.type, a.class,
  ST_Translate(
    ST_Force3D(a.geom),
    0,0,
    COALESCE(min(
      PC_PatchMin(
        PC_FilterEquals(pa,'classification',9)
        ,'z')
      )
    ,0)
  ) geom
  FROM polygons a
  LEFT JOIN adam_pointcloud.patches b
  ON PC_Intersects(a.geom,pa)
  GROUP BY a.id, a.type, a.class, a.geom
)
,triangles AS (
  SELECT
    id,
    ST_MakePolygon(
      ST_ExteriorRing(
        (ST_Dump(ST_Triangulate2DZ(a.geom))).geom
      )
    ) geom
  FROM polygonsz a
)
,assign_triags AS (
  SELECT   a.*, b.type, b.class
  FROM triangles a
  INNER JOIN polygons b
  ON ST_Contains(b.geom, a.geom)
  --,bounds c
  --WHERE ST_Intersects(ST_Centroid(b.geom), c.geom)
  --AND a.id = b.id
)
SELECT _south::text || _west::text || p.id AS id,
'water' as type,
ST_AsX3D(ST_Collect(p.geom),3) as geom
FROM assign_triags p
GROUP BY p.id, p.type;