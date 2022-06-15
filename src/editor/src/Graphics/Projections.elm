module Graphics.Projections exposing (..)

{-
    We have 'world' space, a 2d cartesian coordinate system. (a plane if you must)
    Top left is the origin (0,0)
         (0,0)
           o-------------------> [x]
           |
           |
           |
           |
           v
          [y]



   A Camera2D is a orthographic projection of the 'world' space to a 'screen' space, which is rendered through the viewport
     which is thus a transformation (scaling, rotating, translating) of the 'world' space to 'camera' (screen) space



         (0,0)
           o-------------------> [world(x)]
           |    <0,0> (screen)
           |    [3,3] (world)
           |    ++++++++++
           |    +        +
           |    +        +
           v    ++++++++++
          [world(y)]

-}

import Graphics.Angle exposing (Angle(..), addAngle)
import Graphics.Basics exposing (Size, halfSize, scaleSize)
import Graphics.Matrix2 as Matrix2
import Graphics.Shapes.Rectangle exposing (addSize, centerOf)
import Graphics.Vector2 as V2 exposing (Vector2)


{-| Represents a type in world-space
-}
type World a world
    = World a


valueOfWorld : World a world -> a
valueOfWorld world =
    let
        (World a) =
            world
    in
    a


mapWorld : (a -> b) -> World a world -> World b world
mapWorld func (World value) =
    World (func value)


unwrapWorld (World value) =
    value


{-|

    map2World Vector2.add (World { x = 1, y = 2 }) (World { x = 100, y = -10 })

-}
map2World : (a -> b -> c) -> World a world -> World b world -> World c world
map2World func (World valueA) (World valueB) =
    World (func valueA valueB)


map3World : (a -> b -> c -> d) -> World a world -> World b world -> World c world -> World d world
map3World func (World valueA) (World valueB) (World valueC) =
    World (func valueA valueB valueC)


{-| Represents a type in screen-space
-}
type Screen a screen
    = Screen a



-- todo add annotation to stay in screen space


mapScreen func (Screen value) =
    Screen (func value)


unwrapScreen (Screen value) =
    value


{-|

    map2Screen Vector2.add (Screen { x = 1, y = 2 }) (Screen { x = 100, y = -10 })

-}
map2Screen : (a -> b -> c) -> Screen a screen -> Screen b screen -> Screen c screen
map2Screen func (Screen valueA) (Screen valueB) =
    Screen (func valueA valueB)


type alias Coord world screen =
    SpaceBounded V2.Vector2 world screen



{- = WorldCoord (World Vector2 world)
   | ScreenCoord (Screen Vector2 screen)
-}


type SpaceBounded a world screen
    = WorldSpace (World a world)
    | ScreenSpace (Screen a screen)


type alias Viewport screen =
    { {- width : Screen Float screen
         , height : Screen Float screen
      -}
      size : Screen Size screen

    -- here some event type handle ish interface thingy for when the viewport changes
    }


viewportSizeCentre : Camera2d world screen -> World Vector2 world
viewportSizeCentre camera =
    mapScreenToWorld
        (\vwSize ->
            World <|
                V2.fromTuple <|
                    halfSize
                        (scaleSize (1 / camera.zoom) vwSize)
        )
        camera.viewport.size


mapWorldToScreen : (a -> Screen b screen) -> World a world -> Screen b screen
mapWorldToScreen mapFunc (World value) =
    mapFunc value


mapScreenToWorld : (a -> World b world) -> Screen a screen -> World b world
mapScreenToWorld mapFunc (Screen value) =
    mapFunc value


viewPortWorldSize : Camera2d world screen -> World Size world
viewPortWorldSize camera =
    mapScreenToWorld
        (\vwSize ->
            World <| scaleSize (1 / camera.zoom) vwSize
        )
        camera.viewport.size


type alias Camera vecType world screen =
    { viewport : Viewport screen
    , -- the top left position of the camera ( I think)
      positionedAt : World vecType world
    , -- the centre origin of the camera
      origin : World vecType world
    , rotation : Angle
    , zoom : Float
    , minZoom : Float
    , maxZoom : Float
    }


type alias Camera2d world screen =
    Camera V2.Vector2 world screen


createCamera2d : Size -> Camera2d world screen
createCamera2d viewportSizeInPx =
    { viewport = { size = Screen viewportSizeInPx }
    , positionedAt = World V2.zeroVector
    , origin = World (V2.fromTuple <| halfSize viewportSizeInPx)
    , rotation = Radians 0
    , zoom = 1
    , minZoom = 0.01
    , maxZoom = 2
    }


updateViewPort viewportSizeInPx camera =
    { camera | viewport = { size = Screen viewportSizeInPx } }


{-| -}
getWorldPosition : Camera vecType world screen -> World vecType world
getWorldPosition camera =
    camera.positionedAt


{-| Move a camera by the given vector _relative_ to the camera.
-}
moveBy2d : Coord world screen -> Camera V2.Vector2 world screen -> Camera V2.Vector2 world screen
moveBy2d offset camera =
    case offset of
        WorldSpace worldVector ->
            { camera | positionedAt = map2World V2.add camera.positionedAt worldVector }

        ScreenSpace screenVector ->
            { camera | positionedAt = map2World V2.add camera.positionedAt (screenToWorld2d screenVector camera) }


lookAt2d : World V2.Vector2 world -> Camera V2.Vector2 world screen -> Camera V2.Vector2 world screen
lookAt2d (World worldPosition) camera =
    -- we look at a worldPosition, that should be in the centre
    --   the position of the camera is topLeft, so we subtract the offset to the centre
    --   however we need the centre offset to be in world-space, and the viewport is in screen-space
    --  Since only the size matters, and the only thing that influences size is the scale / zoom, we need not to a whole
    --    matrix multiplication, but just scale with the size
    let
        (World centrePointRelative) =
            viewportSizeCentre camera
    in
    { camera
        | positionedAt =
            -- = worldPosition - half viewport (center) -- because the lookAt point should be the center of the screen
            World <|
                V2.add
                    worldPosition
                    (V2.negate centrePointRelative)
    }


centreOfScreen camera =
    let
        (World centrePointRelative) =
            viewportSizeCentre camera
    in
    mapWorld (\cameraVector2 -> V2.add cameraVector2 centrePointRelative) camera.positionedAt


zoomIn : Float -> Camera vecType world screen -> Camera vecType world screen
zoomIn deltaZoom camera =
    setZoom (camera.zoom + deltaZoom) camera


zoomInOn2d : Float -> World Vector2 world -> Camera2d world screen -> Camera2d world screen
zoomInOn2d deltaZoom focusPoint camera =
    lookAt2d focusPoint <|
        setZoom (camera.zoom + deltaZoom) <|
            setOrigin2d focusPoint camera


zoomOutOn2d : Float -> World Vector2 world -> Camera2d world screen -> Camera2d world screen
zoomOutOn2d deltaZoom focusPoint camera =
    lookAt2d focusPoint <|
        setZoom (camera.zoom - deltaZoom) <|
            setOrigin2d focusPoint camera


zoomOut : Float -> Camera vecType world screen -> Camera vecType world screen
zoomOut deltaZoom camera =
    setZoom (camera.zoom - deltaZoom) camera


setZoom : Float -> Camera vecType world screen -> Camera vecType world screen
setZoom zoom camera =
    { camera | zoom = clamp camera.minZoom camera.maxZoom zoom }


resetZoom : Camera vecType world screen -> Camera vecType world screen
resetZoom camera =
    { camera | zoom = 1 }


setRotate : Angle -> Camera vecType world screen -> Camera vecType world screen
setRotate angle camera =
    { camera | rotation = angle }


rotate : Angle -> Camera vecType world screen -> Camera vecType world screen
rotate deltaAngle camera =
    { camera | rotation = addAngle camera.rotation deltaAngle }


setOrigin2d : World V2.Vector2 world -> Camera V2.Vector2 world screen -> Camera V2.Vector2 world screen
setOrigin2d origin camera =
    { camera | origin = origin }


worldToScreen2d : World V2.Vector2 world -> Camera V2.Vector2 world screen -> Screen V2.Vector2 screen
worldToScreen2d (World worldPosition) camera =
    Screen <|
        Matrix2.transform
            (createViewMatrix2d camera)
            -- todo: dont build the matrix each time
            worldPosition


screenToWorld2d : Screen V2.Vector2 screen -> Camera V2.Vector2 world screen -> World V2.Vector2 world
screenToWorld2d (Screen screenPosition) camera =
    -- viewPort x and y are zero for now
    World <|
        Matrix2.transform (Matrix2.invert (createViewMatrix2d camera))
            screenPosition



{- public override Vector2 ScreenToWorld(Vector2 screenPosition)
   {
       var viewport = _viewportAdapter.Viewport;
       return Vector2.Transform(screenPosition - new Vector2(viewport.X, viewport.Y),
           Matrix.Invert(GetViewMatrix()));
   }
-}
-- TODO: GetViewSizeInWorldUnits bounding rectangles and frustrum stuff ... :s


createViewMatrix2d : Camera V2.Vector2 world screen -> Matrix2.Matrix2
createViewMatrix2d camera =
    let
        (World worldPosition) =
            camera.positionedAt

        (World worldCameraOrigin) =
            camera.origin
    in
    Matrix2.createB worldPosition camera.rotation { x = camera.zoom, y = camera.zoom } worldCameraOrigin


createViewMatrix2dForSvg : Camera V2.Vector2 world screen -> Matrix2.Matrix2
createViewMatrix2dForSvg camera =
    let
        (World worldPosition) =
            camera.positionedAt

        (World worldCameraOrigin) =
            camera.origin
    in
    Matrix2.createA (V2.negate worldPosition) camera.rotation { x = camera.zoom, y = camera.zoom } worldCameraOrigin


calculateScaleFactorForBoundingBox : World { a | width : Float, height : Float } world -> Screen Size screen -> Float
calculateScaleFactorForBoundingBox (World objectToFitInViewport) (Screen viewportSizeInPx) =
    -- we do the multiplication because the viewport is not square
    --   so we take the aspect ratio into consideration
    let
        objectAbsWidth =
            Basics.abs objectToFitInViewport.width

        objectAbsHeight =
            Basics.abs objectToFitInViewport.height
    in
    case (objectAbsWidth * viewportSizeInPx.height) > (objectAbsHeight * viewportSizeInPx.width) of
        True ->
            viewportSizeInPx.width / objectAbsWidth

        False ->
            viewportSizeInPx.height / objectAbsHeight


zoomToFit : World Graphics.Shapes.Rectangle.Rectangle world -> Size -> World V2.Vector2 world -> Camera2d world screen -> Camera2d world screen
zoomToFit boundingBox margin origin camera =
    let
        cameraScaleFactor =
            -- add one barrier length to the width and height
            calculateScaleFactorForBoundingBox
                (mapWorld (addSize margin) boundingBox)
                camera.viewport.size
    in
    lookAt2d (mapWorld centerOf boundingBox) <|
        setRotate (Degrees 0) <|
            setZoom cameraScaleFactor <|
                setOrigin2d origin camera
