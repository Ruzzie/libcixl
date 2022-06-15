module Graphics.Shapes.Rectangle exposing (..)

import Graphics.Basics exposing (Size)
import Graphics.Vector2 as Vector2 exposing (Vector2)


{-|

    Represents a rectangle

  - `x` is the x coordinate of the top-left corner
  - `y` is the y coordinate of the top-left corner
  - `width` is the width of this rectangle
  - `height` is the height of this rectangle

-}
type alias Rectangle =
    { x : Float
    , y : Float
    , width : Float
    , height : Float
    }


zeroRect =
    Rectangle 0 0 0 0


toString : Rectangle -> String
toString rect =
    "{X:" ++ String.fromFloat rect.x ++ " Y:" ++ String.fromFloat rect.y ++ " Width:" ++ String.fromFloat rect.width ++ " Height:" ++ String.fromFloat rect.height ++ "}"


type alias Point =
    Vector2


centerOf : Rectangle -> Point
centerOf rect =
    Vector2
        (rect.x + (rect.width / 2))
        (rect.y + (rect.height / 2))


sizeOf : Rectangle -> Size
sizeOf rect =
    Graphics.Basics.sizeOf rect


createFromPoint point size =
    Rectangle point.x point.y size.width size.height


topLeft : Rectangle -> Vector2
topLeft rect =
    Vector2 rect.x rect.y


getPoints : Rectangle -> List Vector2
getPoints rect =
    [ Vector2 rect.x rect.y, Vector2 (rect.x + rect.width) rect.y, Vector2 (rect.x + rect.width) (rect.y + rect.height), Vector2 rect.width rect.y ]


createFromBounds minimum maximum =
    Rectangle minimum.x minimum.y (maximum.x - minimum.x) (maximum.y - minimum.y)


{-| Given a list of `Vector2` finds the minima and maxima and returns the bounding rectangle
-}
boundingRectangleOfList : List Vector2 -> Maybe Rectangle
boundingRectangleOfList vectorList =
    Maybe.map2 createFromBounds
        (Vector2.minimum vectorList)
        (Vector2.maximum vectorList)



addSize : Size -> Rectangle -> Rectangle
addSize size rect =
    { rect | width = rect.width + size.width, height = rect.height + size.height }


{-| Inflates a `Rectangle` from the center by given amounts

    inflate { x = 10, y = 10, width = 4, height = 8 } 2 2 == { height = 12, width = 8, x = 8, y = 8 }

-}
inflate rect horizontalAmount verticalAmount =
    { rect
        | x = rect.x - horizontalAmount
        , y = rect.y - verticalAmount
        , width = rect.width + (2 * horizontalAmount)
        , height = rect.height + (2 * verticalAmount)
    }

{-| Inflates a `Rectangle` from the center by given scale

     inflate { x = 10, y = 10, width = 4, height = 8 } 0.25 == { height = 12, width = 8, x = 8, y = 8 }
-}
inflateByFactor scaleFactor rect =
    inflate rect (scaleFactor * rect.width) (scaleFactor * rect.height)
