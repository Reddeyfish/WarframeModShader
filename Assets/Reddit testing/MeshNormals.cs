using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MeshNormals : MonoBehaviour {

	// Use this for initialization
	void Start () {
        Mesh mesh = GetComponent<MeshFilter>().mesh;

        Vector3[] meshVertices = mesh.vertices;
        //map vertex positions to the ids of all vertices at that position
        Dictionary<Vector3, List<int>> vertexMerge = new Dictionary<Vector3, List<int>>();
        for(int i = 0; i < mesh.vertexCount; i++) {
            Vector3 vectorPosition = meshVertices[i];

            if(!vertexMerge.ContainsKey(vectorPosition)) {
                //if not already in our collection as a key, add it as a key
                vertexMerge.Add(vectorPosition, new List<int>());
            }

            //add the vertex id to our collection
            vertexMerge[vectorPosition].Add(i);
        }

        //map vertexIDs to the averaged normal
        Vector3[] meshNormals = mesh.normals;
        Vector3[] vertexAveragedNormals = new Vector3[mesh.vertexCount];

        foreach (List<int> duplicatedVertices in vertexMerge.Values) {
            //calculate average normal
            Vector3 sumOfNormals = Vector3.zero;
            foreach (int vertexIndex in duplicatedVertices) {
                sumOfNormals += meshNormals[vertexIndex];
            }

            Vector3 averagedNormal = (sumOfNormals /= duplicatedVertices.Count).normalized; //average is sum divided by the number of summed elements

            //write the result to our output
            foreach (int vertexIndex in duplicatedVertices) {
                vertexAveragedNormals[vertexIndex] = averagedNormal;
            }
        }


        //write the result to mesh.
        //x and y components shoved into uv3, z component shoved into uv4, with w component of 1.
        Vector2[] vertexAveragedNormalsXY = new Vector2[mesh.vertexCount];
        Vector2[] vertexAveragedNormalsZW = new Vector2[mesh.vertexCount];
        for(int i = 0; i < mesh.vertexCount; i++) {
            Vector3 normal = vertexAveragedNormals[i];
            vertexAveragedNormalsXY[i] = new Vector2(normal.x, normal.y);
            vertexAveragedNormalsZW[i] = new Vector2(normal.z, 1);
        }

        mesh.uv3 = vertexAveragedNormalsXY;
        mesh.uv4 = vertexAveragedNormalsZW;
	}
}
