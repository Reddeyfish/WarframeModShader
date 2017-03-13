using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Collider))]
public class ModRotation : MonoBehaviour {

    [SerializeField]
    protected Transform targetRotationTransform; //the transform to be rotated based on where the mouse is

    [SerializeField]
    protected Renderer targetRotationRenderer; //the renderer we're feeding rotation data to for cool shader effects

    [SerializeField]
    protected Vector3 lookOffset= Vector3.zero; //offset added to the targetRotationVector, usually set to a large positive forward value to reduce the angle range that can be achieved

    [SerializeField]
    protected float heightmapOffsetScalar = 0.025f; //scalar multiplied against the vector fed to the shader for heightmap offset

    [SerializeField]
    protected float smoothTime = 0.1f; //smoothTime parameter to SmoothDamp

    Vector3 targetRotationVector = Vector3.zero; //where the uneased target mouse position is in our local object space
    Vector3 actualRotationVector = Vector3.zero; //where our actual eased position is, used to compute our current rotation
    Vector3 currentRotationVelocity = Vector3.zero; //Value held for use in SmoothDamp, please avoid modifying this


    Collider mouseCollider;
	// Use this for initialization
	void Start () {
        mouseCollider = GetComponent<Collider>();
    }

    void OnMouseOver() {
        //update target rotation vector
        Ray mouseRay = Camera.main.ScreenPointToRay(Input.mousePosition);
        RaycastHit hitInfo;
        mouseCollider.Raycast(mouseRay, out hitInfo, float.MaxValue); //use raycasting to determine where exactly the mouse is on our collider
        targetRotationVector = transform.InverseTransformPoint(hitInfo.point);
    }
    void OnMouseExit() {
        //set target rotation vector to zero
        targetRotationVector = Vector3.zero;
    }

    void Update() {

        actualRotationVector = Vector3.SmoothDamp(actualRotationVector, targetRotationVector, ref currentRotationVelocity, smoothTime);

        //use negative targetRotationVector so the rotation moves along with the mouse
        targetRotationTransform.rotation = Quaternion.LookRotation(transform.TransformPoint(lookOffset - actualRotationVector), Vector3.up);

        MaterialPropertyBlock targetMaterialPropertyBlock = new MaterialPropertyBlock();
        int offsetVectorID = Shader.PropertyToID("_OffsetVector"); //ID of the property we want to set
        //again, negative targetRotationVector so the offset moves with the mouse
        targetMaterialPropertyBlock.SetVector(offsetVectorID, heightmapOffsetScalar * -actualRotationVector);
        targetRotationRenderer.SetPropertyBlock(targetMaterialPropertyBlock);

    }
}
