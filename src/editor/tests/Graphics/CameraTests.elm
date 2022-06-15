module Graphics.CameraTests exposing (..)

import Expect exposing (Expectation, FloatingPointTolerance(..))
import Fuzz exposing (float, floatRange)
import Graphics.Angle exposing (Angle(..))
import Graphics.Projections exposing (Screen(..), World(..), calculateScaleFactorForBoundingBox, createCamera2d, lookAt2d, screenToWorld2d, setRotate, setZoom, unwrapWorld, worldToScreen2d, zoomIn, zoomOut, zoomToFit)
import Graphics.Vector2 as Vector2 exposing (Vector2)
import Test exposing (..)


suite : Test
suite =
    describe "Camera functions tests"
        [ describe "scaleToBoundingBox"
            [ test "zoom out (scale less than 1) on width" <|
                \_ ->
                    let
                        objectSizeToFit =
                            World { width = 20, height = 10 }

                        viewPortSizeInPx =
                            Screen { width = 2, height = 2 }
                    in
                    Expect.within (Absolute 0.0000000000001)
                        (calculateScaleFactorForBoundingBox objectSizeToFit viewPortSizeInPx)
                    <|
                        0.1
            , test "zoom out (scale less than 1) on height" <|
                \_ ->
                    let
                        objectSizeToFit =
                            World { width = 10, height = 20 }

                        viewPortSizeInPx =
                            Screen { width = 2, height = 2 }
                    in
                    Expect.within (Absolute 0.0000000000001)
                        (calculateScaleFactorForBoundingBox objectSizeToFit viewPortSizeInPx)
                    <|
                        0.1
            , test "zoom out (scale less than 1) same aspect ratio's" <|
                \_ ->
                    let
                        objectSizeToFit =
                            World { width = 20, height = 20 }

                        viewPortSizeInPx =
                            Screen { width = 2, height = 2 }
                    in
                    Expect.within (Absolute 0.0000000000001)
                        (calculateScaleFactorForBoundingBox objectSizeToFit viewPortSizeInPx)
                    <|
                        0.1
            , test "zoom out (scale less than 1) square on wide screen viewport" <|
                \_ ->
                    let
                        objectSizeToFit =
                            World { width = 20, height = 20 }

                        viewPortSizeInPx =
                            Screen { width = 4, height = 2 }
                    in
                    Expect.within (Absolute 0.0000000000001)
                        (calculateScaleFactorForBoundingBox objectSizeToFit viewPortSizeInPx)
                    <|
                        0.1
            , test "NEW:: camera2d smoke test" <|
                \_ ->
                    let
                        -- lets imagine our world space is 1000 x 1000
                        --   our viewport is 200x100
                        --    the origin is initially focused on the center of the viewport????
                        -- so first lets see if projecting works
                        --
                        camera =
                            lookAt2d (World { x = 400, y = 300 }) (createCamera2d { width = 200, height = 100 })
                    in
                    Expect.equal
                        camera.positionedAt
                    <|
                        World { x = 300, y = 250 }
            , test "NEW:: camera2d smoke test, project no scaling and rotation" <|
                \_ ->
                    let
                        -- lets imagine our world space is 1000 x 1000
                        --   our viewport is 200x100
                        --    the origin is initially focused on the center of the viewport????
                        -- so first lets see if projecting works
                        --
                        camera =
                            lookAt2d (World { x = 400, y = 300 }) (createCamera2d { width = 200, height = 100 })

                        (Screen coord) =
                            worldToScreen2d (World { x = 1, y = 1 }) camera
                    in
                    Expect.equal
                        coord
                    <|
                        { x = -299, y = -249 }
            , test "NEW:: camera2d smoke test, project with zoom out 0.5" <|
                \_ ->
                    let
                        --    the origin is initially focused on the center of the viewport????
                        camera =
                            zoomOut 0.5 <|
                                -- zoom to 0.5
                                lookAt2d (World { x = 20, y = 20 }) (createCamera2d { width = 10, height = 10 })

                        (Screen coord) =
                            worldToScreen2d (World { x = 10, y = 10 }) camera
                    in
                    Expect.equal
                        coord
                    <|
                        { x = 0, y = 0 }
            , test "NEW:: camera2d smoke test, project with zoomIn 2x" <|
                \_ ->
                    let
                        camera =
                            zoomIn 1 <|
                                -- zoom to 2
                                lookAt2d (World { x = 10, y = 10 }) (createCamera2d { width = 10, height = 10 })

                        (Screen coord) =
                            worldToScreen2d (World { x = 0, y = 0 }) camera
                    in
                    Expect.equal
                        coord
                    <|
                        { x = -15, y = -15 }
            , test "NEW:: camera2d smoke test, project with rotate 90" <|
                \_ ->
                    let
                        camera =
                            setRotate (Degrees 90) <|
                                lookAt2d (World { x = 5, y = 10 }) (createCamera2d { width = 10, height = 20 })

                        (Screen coord) =
                            worldToScreen2d (World { x = 0, y = 0 }) camera
                    in
                    Expect.equal
                        coord
                    <|
                        -- dunno could be ok ....
                        { x = 15, y = 4.999999999999999 }
            , test "NEW:: camera2d smoke test, sample data" <|
                \_ ->
                    let
                        -- took some data from the screen
                        camera =
                            zoomOut 0.7 <|
                                setRotate (Degrees 80) <|
                                    lookAt2d (World { x = 8256049.782853578, y = 18976356.576977167 }) (createCamera2d { width = 1560, height = 596 })

                        (Screen coord) =
                            worldToScreen2d (World { x = 8255096, y = 18976698 }) camera
                    in
                    Expect.equal
                        coord
                    <|
                        -- and it is in the vicinity so looks alright
                        { x = 629.4423916935921, y = 33.9984210501425 }
            ]
        , describe "camera2d screenToWorld and worldToScreen"
            [ fuzz (floatRange 0.05 2) "with zoom" <|
                \fuzzZoom ->
                    let
                        camera =
                            setZoom fuzzZoom <|
                                -- zoom to 2
                                lookAt2d (World { x = 10, y = 10 }) (createCamera2d { width = 500, height = 500 })

                        worldCoord =
                            World { x = 0, y = 0 }

                        result =
                            screenToWorld2d
                                (worldToScreen2d worldCoord camera)
                                camera
                    in
                    -- the project / un-project should return the original worldCoord
                    vector2ExpectWithin
                        (Absolute 0.005)
                        (unwrapWorld result)
                        (unwrapWorld worldCoord)
            , fuzz (Fuzz.tuple ( floatRange 0.05 2, floatRange 0 360 )) "with zoom and rotate" <|
                \( fuzzZoom, fuzzAngle ) ->
                    let
                        camera =
                            setZoom fuzzZoom <|
                                setRotate (Degrees fuzzAngle) <|
                                    -- zoom to 2
                                    lookAt2d (World { x = 10, y = 10 }) (createCamera2d { width = 500, height = 500 })

                        worldCoord =
                            World { x = 0, y = 0 }

                        result =
                            screenToWorld2d
                                (worldToScreen2d worldCoord camera)
                                camera
                    in
                    -- the project / un-project should return the original worldCoord
                    vector2ExpectWithin
                        (Absolute 0.005)
                        (unwrapWorld result)
                        (unwrapWorld worldCoord)
            ]
        ]


vector2ExpectWithin : FloatingPointTolerance -> Vector2 -> Vector2 -> Expectation
vector2ExpectWithin tolerance a b =
    Expect.all
        [ \subject -> Expect.within tolerance subject.x b.x
        , \subject -> Expect.within tolerance subject.y b.y
        ]
        a
