using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(MeshGeneration))]
public class MeshGenerationEditor : Editor {

    public override void OnInspectorGUI() {
        DrawDefaultInspector();

        MeshGeneration myScript = (MeshGeneration)target;
        if (GUILayout.Button("Generate")) {
            myScript.GenerateMesh();
        }
    }
}