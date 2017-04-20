 WITH
 bounds AS (
  SELECT ST_Segmentize(ST_MakeEnvelope(_west, _south, _east, _north, 28992),_segmentlength) geom
 ),

     pointcloud AS (
  SELECT PC_FilterGreaterThan(
      PC_FilterEquals(
        PC_FilterEquals(pa,'classification',1),
      'NumberOfReturns',1),
    'Intensity',150) pa --unclassified points
      FROM ahn3_pointcloud.patches, bounds
      WHERE ST_DWithin(geom, pc_envelope(pa),10)
    ),

 pointcloud_all AS (
  SELECT pa pa --all points
  FROM ahn3_pointcloud.patches, bounds
  WHERE ST_DWithin(geom,pc_envelope(pa),10)
 ),
 footprints AS (
  SELECT ST_Force3D(ST_Intersection(a.geometrie, b.geom)) geom,
  identificatie_lokaalid id
  FROM imgeo.imgeo_kunstwerkdeel a, bounds b
  WHERE 1 = 1
  AND (bgt_type = 'steiger')
  AND ST_Intersects(a.geometrie, b.geom)
 ),
 papoints AS ( --get points from intersecting patches
  SELECT
    a.id,
    PC_Explode(b.pa) pt,
    geom footprint
  FROM footprints a
  LEFT JOIN pointcloud b ON PC_Intersects(a.geom, b.pa)
 ),
 footprintpatch AS ( --get only points that fall inside building, patch them
  SELECT id, PC_Patch(pt) pa, footprint
  FROM papoints WHERE ST_Intersects(footprint, Geometry(pt))
  GROUP BY id, footprint
 ),
 polygons AS (
  SELECT id, ST_Extrude(ST_Tesselate(ST_Translate(footprint,0,0, PC_PatchMin(pa,'z')+0.4)),0,0,0.2) geom FROM footprintpatch
 )
 SELECT id,'steiger' as type, 'grey' color, ST_AsX3D(p.geom) geom
 FROM polygons p

