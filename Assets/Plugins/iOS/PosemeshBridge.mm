#import <Posemesh/Posemesh.h>

extern "C" {
    static PSMPosemesh *pm;

    void unity_pnpSolveForObjectPoints(
        float* objectPoints, 
        float* imagePoints, 
        float* cameraMatrix, 
        float* outR, 
        float* outT
    ) {
        if (pm == NULL) {
            pm = [[PSMPosemesh alloc] init];
        }
        [pm pnpSolveForObjectPoints:objectPoints 
                        imagePoints:imagePoints 
                        cameraMatrix:cameraMatrix 
                                outR:outR 
                                outT:outT];
    }
}