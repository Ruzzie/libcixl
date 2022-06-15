module Graphics.Matrix2 exposing (..)

import Graphics.Angle as Angle
import Graphics.Vector2 as Vector2 exposing (Vector2)


type alias Matrix2 =
    { -- x scale, also used for rotation
      m11 : Float
    , --  used for rotation
      m12 : Float
    , -- // used for rotation
      m21 : Float
    , -- y scale, also used for rotation
      m22 : Float
    , -- x translation
      m31 : Float
    , -- y translation
      m32 : Float
    }



-- only x scale and y scale are 1, the rest 0, so no operations


identity =
    { m11 = 1
    , m12 = 0
    , m21 = 0
    , m22 = 1
    , m31 = 0
    , m32 = 0
    }


zero =
    { m11 = 0
    , m12 = 0
    , m21 = 0
    , m22 = 0
    , m31 = 0
    , m32 = 0
    }


{-| sets m32 and m32 (x,y) with the given vector2 value
-}
setXYTranslation vector matrix =
    { matrix | m31 = vector.x, m32 = vector.y }


{-| Transforms a `vector` by a given `Matrix2`
-}
transform matrix2 vector2 =
    Vector2 (vector2.x * matrix2.m11 + vector2.y * matrix2.m21 + matrix2.m31)
        (vector2.x * matrix2.m12 + vector2.y * matrix2.m22 + matrix2.m32)


{-| /// <summary>
/// Calculates the <see cref="Matrix2" /> struct that can be used to scale a set vertices.
/// </summary>
/// <param name="scale">The amounts to scale by on the x and y axes.</param>
/// <param name="result">The resulting <see cref="Matrix2" />.</param>
-}
createScale scaleXY =
    { m11 = scaleXY.x
    , m12 = 0
    , m21 = 0
    , m22 = scaleXY.y
    , m31 = 0
    , m32 = 0
    }


{-| /// <summary>
/// Calculates the <see cref="Matrix2" /> struct that can be used to translate a set vertices.
/// </summary>
/// <param name="position">The amounts to translate by on the x and y axes.</param>
/// <param name="result">The resulting <see cref="Matrix2" />.</param>
-}
createTranslation position =
    { identity | m31 = position.x, m32 = position.y }


{-| /// <summary>
/// Calculates the <see cref="Matrix2" /> struct that can be used to rotate a set of vertices around the z-axis.
/// </summary>
/// <param name="radians">The amount, in radians, in which to rotate around the z-axis.</param>
/// <param name="result">The resulting <see cref="Matrix2" />.</param>
-}
createRotationZ angle =
    let
        val1 =
            Basics.cos (Angle.radiansValue angle)

        val2 =
            Basics.sin (Angle.radiansValue angle)
    in
    { m11 = val1
    , m12 = val2
    , m21 = -val2
    , m22 = val1
    , m31 = 0
    , m32 = 0
    }


{-| calculates the determinant of the `Matrix2`
-}
determinantOf matrix =
    (matrix.m11 * matrix.m22) - (matrix.m12 * matrix.m21)


{-| calculates the inversion of a `Matrix2`
-}
invert matrix =
    let
        invDet =
            1 / determinantOf matrix
    in
    { m11 = matrix.m22 * invDet
    , m12 = -matrix.m12 * invDet
    , m21 = -matrix.m21 * invDet
    , m22 = matrix.m11 * invDet
    , m31 = ((matrix.m32 * matrix.m21) - (matrix.m31 * matrix.m22)) * invDet
    , m32 = -((matrix.m32 * matrix.m11) - (matrix.m31 * matrix.m12)) * invDet
    }


{-| multiplication of 2 `Matrix2`'s
-}
multiply : Matrix2 -> Matrix2 -> Matrix2
multiply matrix1 matrix2 =
    { m11 = (matrix1.m11 * matrix2.m11) + (matrix1.m12 * matrix2.m21)
    , m12 = (matrix1.m11 * matrix2.m12) + (matrix1.m12 * matrix2.m22)
    , m21 = (matrix1.m21 * matrix2.m11) + (matrix1.m22 * matrix2.m21)
    , m22 = (matrix1.m21 * matrix2.m12) + (matrix1.m22 * matrix2.m22)
    , m31 = (matrix1.m31 * matrix2.m11) + (matrix1.m32 * matrix2.m21) + matrix2.m31
    , m32 = (matrix1.m31 * matrix2.m12) + (matrix1.m32 * matrix2.m22) + matrix2.m32
    }


add : Matrix2 -> Matrix2 -> Matrix2
add matrix1 matrix2 =
    { m11 = matrix1.m11 + matrix2.m11
    , m12 = matrix1.m11 + matrix2.m12
    , m21 = matrix1.m21 + matrix1.m22
    , m22 = matrix1.m21 + matrix1.m22
    , m31 = matrix1.m31 + matrix2.m31
    , m32 = matrix1.m31 + matrix2.m32
    }


witOriginOrIdentity origin =
    case origin of
        Just originVector2 ->
            -- Set origin in the identity matrix when given
            --   the m31 and m32 are used for translating, so the origin is an offset....
            -- { identity | m31 = -originVector2.x, m32 = -originVector2.y }
            createTranslation <| Vector2.negate originVector2

        Nothing ->
            identity


{-| -- Applies the given scale to a Matrix2
-}
scale : Vector2 -> Maybe Vector2 -> Matrix2 -> Matrix2
scale scaleXYAmount origin =
    multiply
        -- create the scale matrix
        (multiply (witOriginOrIdentity origin) (createScale scaleXYAmount))


{-| Applies a rotation to a target Matrix2
-}
rotate angle target =
    if Angle.isZero angle then
        -- nothing to do so return the target
        target

    else
        multiply target (createRotationZ (Angle.negateAngle angle))


{-| Applies a translation to a target Matrix2
-}
translate translation target =
    multiply target (createTranslation translation)


{-| /// <summary>
/// Gets the rotation angle in radians.
/// </summary>
/// <value>
/// The rotation angle in radians.
/// </value>
/// <remarks>
/// The <see cref="Rotation" /> is equal to <code>Atan2(M21, M11)</code>.
/// </remarks>
-}
getRotation matrix =
    Angle.Radians <| Basics.atan2 matrix.m32 matrix.m11


{-| /// <summary>
/// Gets the translation.
/// </summary>
/// <value>
/// The translation.
/// </value>
/// <remarks>The <see cref="Translation" /> is equal to the vector <code>(M31, M32)</code>.</remarks>
-}
getTranslation matrix =
    { x = matrix.m32, y = matrix.m32 }


{-| /// <summary>
/// Gets the scale.
/// </summary>
/// <value>
/// The scale.
/// </value>
/// <remarks>
/// The <see cref="Scale" /> is equal to the vector
/// <code>(Sqrt(M11 \* M11 + M21 \* M21), Sqrt(M12 \* M12 + M22 \* M22))</code>.
/// </remarks>
-}
getScale matrix =
    { x = Basics.sqrt (matrix.m11 * matrix.m11 + matrix.m21 * matrix.m21)
    , y = Basics.sqrt (matrix.m12 * matrix.m12 + matrix.m22 * matrix.m22)
    }


{-| creates a transformation matrix (that works with the svg transform)
-}
createA position angle scaleXY origin =
    multiply
        (multiply
            (createTranslation <| Vector2.negate origin)
            -- rotation around an origin
            (createRotationZ <| angle)
        )
        (multiply (createTranslation (Vector2.add origin position))
            -- the need to offset the centre of rotation against the given position to translate to
            (createScale scaleXY)
        )


createB position angle scaleXY origin =
    multiply
        (multiply
            (multiply
                (multiply (createTranslation <| Vector2.negate position)
                    (createTranslation <| Vector2.negate origin)
                )
                (createRotationZ <| angle)
            )
            (createScale scaleXY)
        )
        (createTranslation origin)



{- (multiply
       (createTranslation <| Vector2.negate origin)
       -- rotation around an origin
       (createRotationZ <| angle)
   )
   (multiply (createTranslation (Vector2.add origin position))
       -- the need to offset the centre of rotation against the given position to translate to
       (createScale scaleXY)
   )
-}
