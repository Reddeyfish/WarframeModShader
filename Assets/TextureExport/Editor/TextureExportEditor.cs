using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(TextureExport))]
public class TextureExportEditor : Editor {

    public override void OnInspectorGUI() {
        DrawDefaultInspector();

        TextureExport myScript = (TextureExport)target;
        if (GUILayout.Button("Export")) {
            myScript.Export();
        }
    }
}