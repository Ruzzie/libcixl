module Graphics.Vector2 exposing (..)

import Graphics.Basics exposing (lerp)


type alias Vector2 =
    { x : Float
    , y : Float
    }


{-| Creates a new 2-element vector with the given values.
-}
vector2 : Float -> Float -> Vector2
vector2 x y =
    Vector2 x y


{-| A vector with components 0, 0
-}
zeroVector =
    { x = 0, y = 0 }


{-| A vector with components 1, 1
-}
unitVector =
    { x = 1, y = 1 }


{-| Extract the x component of a vector.
-}
getX : { a | x : Float } -> Float
getX =
    .x


{-| Extract the y component of a vector.
-}
getY : { a | y : Float } -> Float
getY =
    .y


{-| Update the x component of a vector, returning a new vector.
-}
setX : Float -> { b | x : Float } -> { b | x : Float }
setX x vector =
    { vector | x = x }


{-| Update the y component of a vector, returning a new vector.
-}
setY : Float -> { b | y : Float } -> { b | y : Float }
setY y vector =
    { vector | y = y }


{-| Convert a vector to a (x,y) Tuple.
-}
toTuple : Vector2 -> ( Float, Float )
toTuple vector =
    ( vector.x, vector.y )


{-| Convert a (x,y) Tuple to a vector.
-}
fromTuple : ( Float, Float ) -> Vector2
fromTuple ( x, y ) =
    { x = x, y = y }


{-| Vector negation: -vector
-}
negate vector =
    { x = -vector.x
    , y = -vector.y
    }


{-| Vector subtraction: vectorA - vectorB
-}
subtract vectorA vectorB =
    { x = vectorA.x - vectorB.x
    , y = vectorA.y - vectorB.y
    }


{-| Vector addition: vectorA + vectorB
-}
add : { a | x : Float, y : Float } -> { b | x : Float, y : Float } -> Vector2
add vectorA vectorB =
    { x = vectorA.x + vectorB.x
    , y = vectorA.y + vectorB.y
    }


{-| Vector subtraction: vectorA - vectorB
-}
sub : { a | x : Float, y : Float } -> { b | x : Float, y : Float } -> Vector2
sub vectorA vectorB =
    { x = vectorA.x - vectorB.x
    , y = vectorA.y - vectorB.y
    }


{-| Multiply the vector by a scalar: scaleFactor \* vector
-}
scale scaleFactor vector =
    multiply vector { x = scaleFactor, y = scaleFactor }


{-| Divide the vector by a scalar: vector / divider
-}
divide divider vector =
    { vector | x = vector.x / divider, y = vector.y / divider }


{-| Multiplies the components of two vectors by each other: vectorA \* vectorB
-}
multiply vectorA vectorB =
    { x = vectorA.x * vectorB.x, y = vectorA.y * vectorB.y }


{-| Rotates a vector with an angle given in radians
-}
rotate : Float -> Vector2 -> Vector2
rotate rads vector =
    let
        cosValue =
            cos rads

        sinValue =
            sin rads
    in
    { vector | x = (vector.x * cosValue) - (vector.y * sinValue), y = (vector.x * sinValue) + (vector.y * cosValue) }


{-| Calculates the angle (in radians) of a vector

best used with a normalized vector

-}
toAngle vector =
    atan2 vector.x -vector.y


{-| Calculate a unit vector with the same direction from a given vector
-}
normalize vector =
    let
        num =
            1.0 / sqrt ((vector.x * vector.x) + (vector.y * vector.y))
    in
    { vector | x = vector.x * num, y = vector.y * num }


{-| Calculates the angle (in radians) between 2 vectors
-}
angleBetween source destination =
    let
        direction =
            subtract destination source
    in
    toAngle (normalize direction)


{-| Rotate one point around a given origin
-}
rotateAround rads origin point =
    let
        diff =
            subtract point origin
    in
    add origin (rotate rads diff)



{- rotateAround( center, angle ) {

   const c = Math.cos( angle );
   const s = Math.sin( angle );

   const x = this.x - center.x;
   const y = this.y - center.y;

   this.x = x * c - y * s + center.x;
   this.y = x * s + y * c + center.y;

   return this;
-}


{-| calculates a Vector2 that contains linear interpolation of the specified vectors based on an amount that is
a weighting value(between 0.0 and 1.0)
-}
lerpVector source destination amount =
    { x = lerp source.x destination.x amount, y = lerp source.y destination.y amount }


{-| A string representation of the vector: "(x,y)"
-}
toString : { a | x : Float, y : Float } -> String
toString vector =
    "(" ++ String.fromFloat vector.x ++ "," ++ String.fromFloat vector.y ++ ")"


{-| Find the maxima of a `Vector2` in a non-empty list.

-- returns a vector with the max x and max y

-}
maximum : List Vector2 -> Maybe Vector2
maximum list =
    aggregateList list max


aggregateList : List a -> (a -> a -> a) -> Maybe a
aggregateList list operation =
    case list of
        head :: tail ->
            Just (List.foldl operation head tail)

        _ ->
            Nothing


{-| Find the larger x and y of two `Vector2`
-}
max : Vector2 -> Vector2 -> Vector2
max a b =
    { x = maxX a b, y = maxY a b }


{-| Find the larger x of two `Vector2`
-}
maxX : Vector2 -> Vector2 -> Float
maxX a b =
    if a.x > b.x then
        a.x

    else
        b.x


{-| Find the larger y of two `Vector2`
-}
maxY : Vector2 -> Vector2 -> Float
maxY a b =
    if a.y > b.y then
        a.y

    else
        b.y


{-| Find the minima of a `Vector2` in a non-empty list.

-- returns a vector with the min x and max y

-}
minimum : List Vector2 -> Maybe Vector2
minimum list =
    aggregateList list min


{-| Find the smaller x and y of two `Vector2`
-}
min : Vector2 -> Vector2 -> Vector2
min a b =
    { x = minX a b, y = minY a b }


{-| Find the smaller x of two `Vector2`
-}
minX : Vector2 -> Vector2 -> Float
minX a b =
    if a.x < b.x then
        a.x

    else
        b.x


{-| Find the smaller y of two `Vector2`
-}
minY : Vector2 -> Vector2 -> Float
minY a b =
    if a.y < b.y then
        a.y

    else
        b.y



-- floor, ceil, clamp etc
