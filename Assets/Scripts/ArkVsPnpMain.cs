using System;
using System.Collections.Generic;
using Auki.Ark;
using Auki.Integration.ARFoundation;
using TMPro;
using UnityEngine;
using UnityEngine.XR.ARFoundation;

public class ArkVsPnpMain : MonoBehaviour
{
    [SerializeField] private TMP_Text statusLabel;
    [SerializeField] private GameObject portalObject;
    [SerializeField] private ARCameraManager cameraManager;

    private const float PortalSideLength = 0.05f;
    private readonly PosemeshWrapper _posemeshWrapper = new();
    private bool _isUsingPnp;
    private bool _isTracking = true;

    private void Start()
    {
        var cameraFrameProvider = CameraFrameProvider.GetOrCreateComponent();
        cameraFrameProvider.OnNewFrameReady += OnNewFrameReady;
        UpdateStatusLabel();
        portalObject.SetActive(false);
    }

    public void DidPressToggle()
    {
        _isUsingPnp = !_isUsingPnp;
        UpdateStatusLabel();
    }

    public void DidPressToggleTracking()
    {
        _isTracking = !_isTracking;
        UpdateStatusLabel();
    }

    private void UpdateStatusLabel()
    {
        var tracking = _isTracking ? "[tracking]" : "[not tracking]";
        statusLabel.text = _isUsingPnp ? $"PnP pose {tracking}" : $"Ark pose {tracking}";
    }

    private async void OnNewFrameReady(CameraFrame frame)
    {
        try
        {
            if (!_isTracking) return;

            var markers = await Ark.ParseTextureForQRs(frame.Texture);
            if (markers.Count == 0) return;

            var first = markers[0];
            var coordinateEnvironment = new CoordinateEnvironment(
                frame.Texture,
                frame.ARProjectionMatrix,
                frame.ARWorldToCameraMatrix
            );

            if (_isUsingPnp)
            {
                DoPnpPoseEstimation(first.Corners, coordinateEnvironment, frame.Texture.height);
            }
            else
            {
                DoArkPoseEstimation(first.Corners, coordinateEnvironment);
            }
        }
        catch (Exception e)
        {
            Debug.LogException(e);
        }
    }

    private void DoPnpPoseEstimation(
        IReadOnlyList<Vector2> corners,
        CoordinateEnvironment coordinateEnvironment,
        float textureHeight
    )
    {
        var outR = new float[9];
        var outT = new float[3];

        _posemeshWrapper.SolvePNP(
            ArkVsPnpHelpers.ObjectPointsForSquareOfSize(PortalSideLength),
            ArkVsPnpHelpers.ImagePointsFromCorners(corners, textureHeight),
            ArkVsPnpHelpers.CameraIntrinsicsMatrix(cameraManager),
            outR,
            outT
        );

        // Convert outR Rodrigues vector to a rotation matrix.
        var poseMatrix = new Matrix4x4();
        poseMatrix.SetRow(0, new Vector4(outR[0], outR[1], outR[2], outT[0]));
        poseMatrix.SetRow(1, new Vector4(outR[3], outR[4], outR[5], outT[1]));
        poseMatrix.SetRow(2, new Vector4(outR[6], outR[7], outR[8], outT[2]));
        poseMatrix.SetRow(3, new Vector4(0, 0, 0, 1));
        poseMatrix = AdjustPoseForScreenOrientation(poseMatrix, Screen.orientation);

        var portalPose = new Pose(
            poseMatrix.GetPosition(),
            poseMatrix.rotation
        );

        // world to portal = world to camera * camera to portal
        portalPose = portalPose.GetTransformedBy(coordinateEnvironment.CameraPoseInWorldSpace());
        UpdatePortalObjectPose(portalPose);
    }

    private void DoArkPoseEstimation(IReadOnlyList<Vector2> corners, CoordinateEnvironment coordinateEnvironment)
    {
        var poseEstimation = Ark.EstimatePose(
            corners,
            PortalSideLength,
            coordinateEnvironment
        );
        UpdatePortalObjectPose(poseEstimation.Pose);
    }

    private void UpdatePortalObjectPose(Pose newPose)
    {
        portalObject.SetActive(true);
        portalObject.transform.SetPositionAndRotation(newPose.position, newPose.rotation);
    }

    private Matrix4x4 AdjustPoseForScreenOrientation(Matrix4x4 matrix, ScreenOrientation orientation)
    {
        if (orientation != ScreenOrientation.Portrait) return matrix;
        var row0 = matrix.GetRow(0);
        var row1 = matrix.GetRow(1);
        matrix.SetRow(0, row1);
        matrix.SetRow(1, -row0);
        return matrix;
    }
}