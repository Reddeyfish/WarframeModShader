using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SliderOnChange : MonoBehaviour {

	// Use this for initialization
	void Start () {
        GetComponent<UnityEngine.UI.Slider>().onValueChanged.AddListener(OnChange);
	}

    void OnChange(float value) {
        Debug.Log(value);
    }
	
	// Update is called once per frame
	void Update () {
		
	}
}
