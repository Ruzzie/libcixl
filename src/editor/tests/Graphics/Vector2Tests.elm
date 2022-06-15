module Graphics.Vector2Tests exposing (..)

import Expect exposing (Expectation, FloatingPointTolerance(..))
import Fuzz exposing (Fuzzer, float, floatRange)
import Graphics.Basics exposing (lerp)
import Graphics.Vector2 as Vector2 exposing (lerpVector, multiply, rotateAround, scale, unitVector, zeroVector)
import Test exposing (..)


fuzzVector2 xFuzzer yFuzzer =
    Fuzz.map2 (\x y -> { x = x, y = y }) xFuzzer yFuzzer


suite : Test
suite =
    describe "The Vector2 module"
        [ describe "Vector2.multiply"
            [ fuzz (fuzzVector2 float float) "scale by zero vector is always zero" <|
                \fuzzVector ->
                    Expect.equal
                        (scale 0 fuzzVector)
                        zeroVector
            , fuzz (fuzzVector2 float float) "multiply by zero vector is always zero" <|
                \fuzzVector ->
                    Expect.equal
                        (multiply zeroVector fuzzVector)
                        zeroVector
            , fuzz (fuzzVector2 float float) "scale by 1  is always original" <|
                \fuzzVector ->
                    Expect.equal
                        (scale 1.0 fuzzVector)
                        fuzzVector
            , fuzz (fuzzVector2 float float) "multiply by 1 vector is always original" <|
                \fuzzVector ->
                    Expect.equal
                        (multiply unitVector fuzzVector)
                        fuzzVector
            ]
        , describe "Vector2.negate"
            [ fuzz (fuzzVector2 float float) "verify both factors are negates" <|
                \fuzzVector ->
                    Expect.equal
                        (Vector2.negate fuzzVector)
                    <|
                        multiply fuzzVector { x = -1, y = -1 }
            ]
        , describe "Vector2.subtract"
            [ fuzz (fuzzVector2 float float) "verify simple subtraction" <|
                \fuzzVector ->
                    Expect.equal
                        (Vector2.subtract fuzzVector fuzzVector)
                    <|
                        zeroVector
            ]
        , describe "Vector2.add"
            [ fuzz (fuzzVector2 float float) "verify simple addition" <|
                \fuzzVector ->
                    Expect.equal
                        (Vector2.add fuzzVector fuzzVector)
                    <|
                        scale 2 fuzzVector
            ]
        , describe "Vector2.divide"
            [ fuzz (fuzzVector2 float float) "verify simple division" <|
                \fuzzVector ->
                    Expect.equal
                        (Vector2.divide 2 fuzzVector)
                    <|
                        scale 0.5 fuzzVector
            ]
        , describe "Vector2.normalize"
            [ fuzz (fuzzVector2 (floatRange -99999.99999 -0.001) (floatRange 0.001 99999.99999)) "verify simple normalisation" <|
                \fuzzVector ->
                    let
                        normalizedVector =
                            Vector2.normalize fuzzVector
                    in
                    Expect.all
                        [ \v -> Expect.atMost 1 v.x
                        , \v -> Expect.atLeast -1 v.x
                        , \v -> Expect.atMost 1 v.y
                        , \v -> Expect.atLeast -1 v.y
                        ]
                        normalizedVector
            , test "1000, 1000 normalize" <|
                \_ -> Expect.equal (Vector2.normalize { x = 1000, y = 1000 }) { x = 0.7071067811865475, y = 0.7071067811865475 }
            ]
        , describe "Vector2.rotate"
            [ test " 90 degrees simple rotation" <|
                \_ ->
                    Expect.equal
                        (Vector2.rotate
                            (degrees 90)
                            { x = 10, y = -20 }
                        )
                    <|
                        { x = 20, y = 9.999999999999998 }
            ]
        , describe "Vector2.toAngle"
            [ test " 0 to angle" <|
                \_ ->
                    Expect.within (Absolute 0.00000001)
                        (Vector2.toAngle { x = 0, y = -1 })
                    <|
                        degrees 0
            , test " 90 angle" <|
                \_ ->
                    Expect.within (Absolute 0.00000001)
                        (Vector2.toAngle { x = 1, y = 0 })
                    <|
                        degrees 90
            ]
        , describe "Vector2.lerp"
            [ test "amount 1.0 returns destination" <|
                \_ ->
                    Expect.equal
                        (lerp 3 5 1.0)
                    <|
                        5
            , test "amount 0.0 returns source" <|
                \_ ->
                    Expect.equal
                        (lerp 3 5 0.0)
                    <|
                        3
            , test "amount 0.5 returns halfway" <|
                \_ ->
                    Expect.equal
                        (lerp 2 4 0.5)
                    <|
                        3
            ]
        , describe "Vector2.lerpVector"
            [ test "amount 1.0 returns destination" <|
                \_ ->
                    Expect.equal
                        (lerpVector { x = 3, y = 2 } { x = 5, y = 4 } 1.0)
                    <|
                        { x = 5, y = 4 }
            , test "amount 0.0 returns source" <|
                \_ ->
                    Expect.equal
                        (lerpVector { x = 3, y = 2 } { x = 5, y = 4 } 0.0)
                    <|
                        { x = 3, y = 2 }
            , test "amount 0.5 returns halfway" <|
                \_ ->
                    Expect.equal
                        (lerpVector { x = 3, y = 2 } { x = 5, y = 4 } 0.5)
                    <|
                        { x = 4, y = 3 }
            ]
        , describe "Vector2.rotateAround"
            [ test "smoke test" <|
                {-
                     |           v after rotation
                     |         o
                     |         .
                     |         .
                     |         .
                     |         .
                   --o---------+---------o-----
                   origin      p         v at start
                -}
                \_ ->
                    Expect.equal (rotateAround (degrees 90) { x = 10, y = 0 } { x = 20, y = 0 }) <|
                        { x = 10, y = 10 }
            ]
        ]
