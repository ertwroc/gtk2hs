--  -*-haskell-*-
--  GIMP Toolkit (GTK) @entry GdkGC@
--
--  Author : Axel Simon
--  Created: 28 September 2002
--
--  Version $Revision: 1.1 $ from $Date: 2002/10/01 15:09:28 $
--
--  Copyright (c) 2002 Axel Simon
--
--  This library is free software; you can redistribute it and/or
--  modify it under the terms of the GNU Library General Public
--  License as published by the Free Software Foundation; either
--  version 2 of the License, or (at your option) any later version.
--
--  This library is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
--  Library General Public License for more details.
--
-- @description@ --------------------------------------------------------------
--
--  Graphics contexts.
--
-- @documentation@ ------------------------------------------------------------
--
-- * This module supplies graphics contexts (GCs) which are a convenient way
--   to pass attributes to drawing functions.
--
-- @todo@ ---------------------------------------------------------------------
--
--
module GdkGC(
  GdkGC,
  GdkGCClass,
  castToGdkGC,
  gcNew,
  GCValues(..),
  newGCValues,
  Color(..),
  foreground,
  background,
  Function(..),
  function,
  Fill(..),
  fill,
  tile,
  stipple,
  clipMask,
  SubwindowMode(..),
  subwindowMode,
  tsXOrigin,
  tsYOrigin,
  clipXOrigin,
  clipYOrigin,
  graphicsExposure,
  lineWidth,
  LineStyle(..),
  lineStyle,
  CapStyle(..),
  capStyle,
  JoinStyle(..),
  joinStyle,
  gcNewWithValues,
  gcSetValues,
  gcGetValues,
  gcSetClipRectangle,
  gcSetClipRegion,
  gcSetDashes) where

import Monad	(liftM, when)
import Maybe	(fromJust, isJust)
import Exception(handle)
import Foreign
import UTFCForeign
import GObject	(makeNewGObject)
{#import Hierarchy#}
import Structs
import GdkEnums	(Function(..), Fill(..), SubwindowMode(..), LineStyle(..), 
		 CapStyle(..), JoinStyle(..))
{#import Region#}	(Region)

{# context lib="gtk" prefix="gdk" #}

-- @constructor gcNew@ Create an empty graphics context.
--
gcNew :: GdkDrawableClass d => d -> IO GdkGC
gcNew d = makeNewGObject mkGdkGC $ {#call unsafe gc_new#} (toGdkDrawable d)


-- @constructor gcNewWithValues@ Creates a graphics context with specific 
-- values.
--
gcNewWithValues :: GdkDrawableClass d => d -> GCValues -> IO GdkGC
gcNewWithValues d gcv = allocaBytes (sizeOf gcv) $ \vPtr -> do
  mask <- pokeGCValues vPtr gcv
  gc <- makeNewGObject mkGdkGC $ {#call unsafe gc_new_with_values#} 
    (toGdkDrawable d) (castPtr vPtr) mask
  handle (const $ return ()) $ when (isJust (tile gcv)) $ 
    touchForeignPtr ((unGdkPixmap.fromJust.tile) gcv)
  handle (const $ return ()) $ when (isJust (stipple gcv)) $ 
    touchForeignPtr ((unGdkPixmap.fromJust.stipple) gcv)
  handle (const $ return ()) $ when (isJust (clipMask gcv)) $ 
    touchForeignPtr ((unGdkPixmap.fromJust.clipMask) gcv)
  return gc

-- @method gcSetValues@ Change some of the values of a graphics context.
--
gcSetValues :: GdkGC -> GCValues -> IO ()
gcSetValues gc gcv = allocaBytes (sizeOf gcv) $ \vPtr -> do
  mask <- pokeGCValues vPtr gcv
  gc <- {#call unsafe gc_set_values#} gc (castPtr vPtr) mask
  handle (const $ return ()) $ when (isJust (tile gcv)) $ 
    touchForeignPtr ((unGdkPixmap.fromJust.tile) gcv)
  handle (const $ return ()) $ when (isJust (stipple gcv)) $ 
    touchForeignPtr ((unGdkPixmap.fromJust.stipple) gcv)
  handle (const $ return ()) $ when (isJust (clipMask gcv)) $ 
    touchForeignPtr ((unGdkPixmap.fromJust.clipMask) gcv)
  return gc

-- @method gcGetValues@ Retrieve the values in a graphics context.
--
gcGetValues :: GdkGC -> IO GCValues
gcGetValues gc = alloca $ \vPtr -> do
  {#call unsafe gc_get_values#} gc (castPtr vPtr)
  peek vPtr

-- @method gcSetClipRectangle@ Set a clipping rectangle.
--
-- * All drawing operations are restricted to this rectangle. This rectangle
--   is interpreted relative to the clip origin.
--
gcSetClipRectangle :: GdkGC -> Rectangle -> IO ()
gcSetClipRectangle gc r = withObject r $ \rPtr ->
  {#call unsafe gc_set_clip_rectangle#} gc (castPtr rPtr)

-- @method gcSetClipRegion@ Set a clipping region.
--
-- * All drawing operations are restricted to this region. This region
--   is interpreted relative to the clip origin.
--
gcSetClipRegion :: GdkGC -> Region -> IO ()
gcSetClipRegion = {#call unsafe gc_set_clip_region#}

-- @method gcSetDashes@ Specify the pattern with which lines are drawn.
--
-- *  Every tuple in the list contains an even and an odd segment. Even
--    segments are drawn normally, whereby the @ref function lineStyle@
--    member of the graphics context defines if odd segements are drawn
--    or not. A @ref arg phase@ argument greater than 0 will drop
--    @ref arg phase@ pixels before starting to draw.
--
gcSetDashes :: GdkGC -> Int -> [(Int,Int)] -> IO ()
gcSetDashes gc phase onOffList = do
  let onOff :: [{#type gint8#}]
      onOff = concatMap (\(on,off) -> [fromIntegral on, fromIntegral off]) 
	      onOffList
  withArray onOff $ \aPtr ->
    {#call unsafe gc_set_dashes#} gc (fromIntegral phase) aPtr
    (fromIntegral (length onOff))
