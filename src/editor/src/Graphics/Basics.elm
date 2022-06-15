module Graphics.Basics exposing (..)


type alias Size =
    { width : Float
    , height : Float
    }


zeroSize : Size
zeroSize =
    Size 0 0


sizeOf : { a | width : Float, height : Float } -> Size
sizeOf shape =
    Size shape.width shape.height


halfSize size =
    ( size.width / 2, size.height / 2 )


scaleSize factor size =
    { size | width = size.width * factor, height = size.height * factor }


{-| Linearly interpolates between two values based on
a weighting value(between 0.0 and 1.0) indicating the weight of the destination value.

Passing amount a value of 0 will cause source to be returned, a value of 1 will cause destination to be returned.

-}
lerp : number -> number -> number -> number
lerp source destination amount =
    source + ((destination - source) * amount)
