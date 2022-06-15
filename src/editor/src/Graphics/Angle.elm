module Graphics.Angle exposing (..)


type Angle
    = Radians Float
    | Degrees Float


mapRadians : (Float -> a) -> Angle -> a
mapRadians func angle =
    func (radiansValue angle)


map2Radians : (Float -> Float -> a) -> Angle -> Angle -> a
map2Radians func angleA angleB =
    func (radiansValue angleA) (radiansValue angleB)


mapDegrees : (Float -> a) -> Angle -> a
mapDegrees func angle =
    func (degreesValue angle)


map : (Angle -> Angle) -> Angle -> Angle
map func angle =
    func angle


map2 : (Angle -> Angle -> Angle) -> Angle -> Angle -> Angle
map2 func angleA angleB =
    func angleA angleB


{-| Angle subtraction: angleA - angleB
-}
subtractAngle angleA angleB =
    Radians (map2Radians (-) angleA angleB)


{-| Angle negation: -angle
-}
negateAngle angle =
    case angle of
        Radians float ->
            Radians -float

        Degrees float ->
            Degrees -float



-- private


radiansValue angle =
    case angle of
        Radians float ->
            float

        Degrees float ->
            Basics.degrees float


degreesValue angle =
    case angle of
        Radians float ->
            float * 180 / pi

        Degrees float ->
            float


{-| Angle addition: a + b
-}
addAngle a b =
    Radians (map2Radians (+) a b)


isZero angle =
    case angle of
        Radians float ->
            float == 0

        Degrees float ->
            float == 0
