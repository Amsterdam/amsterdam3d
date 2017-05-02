 WITH
 bounds AS (
  SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
 ),
 pointcloud_building AS (
  SELECT PC_FilterGreaterThan(
      PC_FilterEquals(
        PC_FilterEquals(pa,'classification',2),
      'NumberOfReturns',1),
    'Intensity',150) pa  --take out trees with nreturns ands intensity
  FROM adam_pointcloud.patches, bounds
  WHERE ST_DWithin(geom, PC_envelope(pa),10) --patches should be INSIDE bounds
 ),
 footprints AS (
  SELECT a.identificatie_lokaalid id, 'border' AS class, a.bgt_type as type,
  ST_Force3D(ST_CurveToLine(a.geometrie)) geom
  FROM imgeo.imgeo_scheiding a
  LEFT JOIN imgeo.bgt_overbruggingsdeel b
  ON St_Intersects((a.geometrie), (b.geometrie)) AND St_Contains(ST_buffer((b.geometrie),1), (a.geometrie))
  ,bounds c
  WHERE a.relatieveHoogteligging > -1
  AND a.bgt_type = 'muur'
  AND (b.geometrie) Is Null
  AND ST_Intersects(a.geometrie, c.geom)
  AND ST_Intersects(ST_Centroid(a.geometrie), c.geom)
 )
 , papoints AS ( --get points from intersecting patches
  SELECT
    a.id,
    PC_Explode(b.pa) pt,
    geom footprint
  FROM footprints a
  LEFT JOIN pointcloud_building b ON PC_Intersects(a.geom, b.pa)
 ),
 papatch AS (
  SELECT
    a.id, PC_PatchMin(PC_Union(pa), 'z') min
  FROM footprints a
  LEFT JOIN pointcloud_building b ON PC_Intersects(a.geom, b.pa)
  GROUP BY a.id
 ),
 footprintpatch AS ( --get only points that fall inside building, patch them
  SELECT id, PC_Patch(pt) pa, footprint
  FROM papoints WHERE ST_Intersects(footprint, Geometry(pt))
  GROUP BY id, footprint
 ),
 stats AS (
  SELECT  a.id, footprint,
    PC_PatchAvg(pa, 'z') max,
    min
  FROM footprintpatch a, papatch b
  WHERE (a.id = b.id)
 ),
 stats_fast AS (
  SELECT
    PC_PatchAvg(PC_Union(pa),'z') max,
    PC_PatchMin(PC_Union(pa),'z') min,
    footprints.id,
    geom footprint
  FROM footprints
  LEFT JOIN pointcloud_building ON PC_Intersects(geom, pa)
  GROUP BY footprints.id, footprint
 ),
 polygons AS (
  SELECT id, ST_Extrude(ST_Translate(footprint,0,0, min), 0,0,max-min) geom FROM stats
 )
 SELECT id,'building' as type, '0.66 0.37 0.13' as color, ST_AsX3D(polygons.geom) geom
 FROM polygons

