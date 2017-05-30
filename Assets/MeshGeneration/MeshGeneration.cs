using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using System.Text;

[RequireComponent(typeof(MeshFilter))]
[RequireComponent(typeof(MeshRenderer))]
public class MeshGeneration : MonoBehaviour {

    [SerializeField]
    protected int numVertices = 16;

    [SerializeField]
    protected float height = 1;

    [SerializeField]
    protected float lowerRadius = 5;

    [SerializeField]
    protected float upperRadius = 5.5f;

    [SerializeField]
    protected string outputFileName = "generatedMesh.obj";
    

    public void GenerateMesh() {
        MeshFilter filter = GetComponent<MeshFilter>();
        Mesh mesh = new Mesh();

        Vector3[] vertices = new Vector3[numVertices * 2];
        int[] triangles = new int[numVertices * 6];
        Vector2[] uvs = new Vector2[numVertices * 2];

        for(int i = 0; i < numVertices; i++) {
            float progress = i / (numVertices - 1.0f);

            int vertexIndexLower = 2 * i;
            int vertexIndexUpper = vertexIndexLower + 1;

            float angle = progress * 2 * Mathf.PI;
            Vector3 direction = new Vector3(Mathf.Cos(angle), 0, Mathf.Sin(angle));

            vertices[vertexIndexLower] = direction * lowerRadius;
            vertices[vertexIndexUpper] = (Vector3)(direction * upperRadius) + (Vector3.up * height);

            uvs[vertexIndexLower] = new Vector2(progress, 0);
            uvs[vertexIndexUpper] = new Vector2(progress, 1);


            triangles[6 * i + 0] = (2 * i) + 0;
            triangles[6 * i + 1] = (2 * i) + 1;
            triangles[6 * i + 2] = (2 * ((i + 1) % numVertices)) + 1;
            
            triangles[6 * i + 3] = (2 * ((i + 1) % numVertices)) + 0;
            triangles[6 * i + 4] = (2 * i) + 0;
            triangles[6 * i + 5] = (2 * ((i + 1) % numVertices)) + 1; 
        }

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.uv = uvs;

        mesh.RecalculateBounds();
        mesh.RecalculateNormals();
        mesh.RecalculateTangents();

        filter.mesh = mesh;

        MeshToFile(filter, outputFileName);
    }

    public static string MeshToString(MeshFilter mf) {
        Mesh m = mf.mesh;
        Material[] mats = mf.GetComponent<MeshRenderer>().materials; 

        StringBuilder sb = new StringBuilder();

        sb.Append("g ").Append(mf.name).Append("\n");
        foreach (Vector3 v in m.vertices) {
            sb.Append(string.Format("v {0} {1} {2}\n", v.x, v.y, v.z));
        }
        sb.Append("\n");
        foreach (Vector3 v in m.normals) {
            sb.Append(string.Format("vn {0} {1} {2}\n", v.x, v.y, v.z));
        }
        sb.Append("\n");
        foreach (Vector3 v in m.uv) {
            sb.Append(string.Format("vt {0} {1}\n", v.x, v.y));
        }
        for (int material = 0; material < m.subMeshCount; material++) {
            sb.Append("\n");
            sb.Append("usemtl ").Append(mats[material].name).Append("\n");
            sb.Append("usemap ").Append(mats[material].name).Append("\n");

            int[] triangles = m.GetTriangles(material);
            for (int i = 0; i < triangles.Length; i += 3) {
                sb.Append(string.Format("f {0}/{0}/{0} {1}/{1}/{1} {2}/{2}/{2}\n",
                    triangles[i] + 1, triangles[i + 1] + 1, triangles[i + 2] + 1));
            }
        }
        return sb.ToString();
    }

    public static void MeshToFile(MeshFilter mf, string filename) {
        using (StreamWriter sw = new StreamWriter(filename)) {
            sw.Write(MeshToString(mf));
        }
    }
}
