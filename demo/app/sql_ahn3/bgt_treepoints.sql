WITH
bounds AS (
  SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
),
 pointcloud AS (
  SELECT PC_FilterEquals(pa,'classification',1) pa --bridge points
  FROM ahn3_pointcloud.patches, bounds
  WHERE ST_DWithin(geom, pc_envelope(pa),10)
 ),
   points AS (
     SELECT PC_Explode(pa) pt
     FROM pointcloud
 ),
 points_filtered AS (
  SELECT * FROM points
  WHERE PC_Get(pt,'ReturnNumber') < PC_Get(pt,'NumberOfReturns') -1
  AND PC_Get(pt,'Intensity') < 150
 )
 SELECT nextval('counter') as id, 'tree' as type, '0 ' || random() * 0.1 ||' 0' as color, ST_AsX3D(ST_Collect(Geometry(pt))) geom
 FROM points_filtered a;