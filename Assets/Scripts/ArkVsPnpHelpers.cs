using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.ARFoundation;

public static class ArkVsPnpHelpers
{
    // Note: Object points are fixed to XY plane for the currently chosen PnP method
    // https://docs.opencv.org/4.x/d9/d0c/group__calib3d.html#gga357634492a94efe8858d0ce1509da869ac5d28b2805d3ac32fd477eee4479406f
    public static float[] ObjectPointsForSquareOfSize(float squareLength) => new[]
    {
        -squareLength / 2, squareLength / 2, 0,
        squareLength / 2, squareLength / 2, 0,
        squareLength / 2, -squareLength / 2, 0,
        -squareLength / 2, -squareLength / 2, 0,
    };

    public static float[] CameraIntrinsicsMatrix(ARCameraManager cameraManager)
    {
        if (!cameraManager.TryGetIntrinsics(out var intrinsics)) return Array.Empty<float>();
        var principalPoint = intrinsics.principalPoint;
        var focalLength = intrinsics.focalLength;

        return new[]
        {
            focalLength.x, 0, principalPoint.x,
            0, focalLength.y, intrinsics.resolution.y - principalPoint.y,
            0, 0, 1,
        };
    }

    public static float[] ImagePointsFromCorners(IReadOnlyList<Vector2> corners, float textureHeight)
    {
        var points = new float[2 * corners.Count];

        for (var i = 0; i < corners.Count; i++)
        {
            var c = corners[i];
            points[2 * i] = c.x;
            // OpenCV coordinates start from top left while Unity's are from bottom left, have to flip Y.
            points[2 * i + 1] = textureHeight - c.y;
        }

        return points;
    }
}