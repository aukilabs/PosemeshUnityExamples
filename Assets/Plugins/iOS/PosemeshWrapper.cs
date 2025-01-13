using System.Runtime.InteropServices;

public class PosemeshWrapper
{
    [DllImport("__Internal")]
    private static extern void unity_pnpSolveForObjectPoints(
        float[] objectPoints,
        float[] imagePoints,
        float[] cameraMatrix,
        float[] outR,
        float[] outT
    );

    public void SolvePNP(
        float[] objectPoints,
        float[] imagePoints,
        float[] cameraMatrix,
        float[] outR,
        float[] outT
    ) => unity_pnpSolveForObjectPoints(
        objectPoints,
        imagePoints,
        cameraMatrix,
        outR,
        outT
    );
}