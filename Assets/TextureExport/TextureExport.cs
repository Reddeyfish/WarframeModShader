using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using System.Text;

public class TextureExport : MonoBehaviour {

    [SerializeField]
    protected Texture2D texture;

    [SerializeField]
    protected string textureName;

    public void Export() {
        toFile(textureToString(texture), textureName + ".js");
    }

    public string textureToString(Texture2D texture) {
        StringBuilder stringBuilder = new StringBuilder();

        stringBuilder.AppendFormat("var {0} = {{}};\n", textureName);
        stringBuilder.AppendFormat("{0}.width = {1};\n", textureName, texture.width);
        stringBuilder.AppendFormat("{0}.height = {1};\n", textureName, texture.height);

        stringBuilder.AppendFormat("{0}.data = [", textureName);
        bool first = true;
        for(int y = 0; y < texture.height; y++) {
            for(int x = 0; x < texture.width; x++) {
                Color color = texture.GetPixel(x, y);
                if(first) {
                    first = false;
                } else {
                    stringBuilder.Append(", ");
                }
                stringBuilder.AppendFormat("{0:f6}, {1:f6}, {2:f6}, {3:f6}", 255.0 * color.r, 255.0 * color.g, 255.0 * color.b, 255.0 * color.a);
            }
        }

        stringBuilder.Append("];\n");

        return stringBuilder.ToString();
    }

    public static void toFile(string data, string filename) {
        using (StreamWriter sw = new StreamWriter(filename)) {
            sw.Write(data);
        }
    }
}
