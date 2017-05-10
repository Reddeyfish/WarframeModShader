using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AdjustParticleLifetime : MonoBehaviour {

    public ParticleSystem particles;

	// Use this for initialization
	void Start () {
        ParticleSystem particles = GetComponent<ParticleSystem>();
        ParticleSystem.MainModule mainModule = particles.main;
        mainModule.startLifetime = new ParticleSystem.MinMaxCurve(min: 1, max: 2);

    }
	
	// Update is called once per frame
	void Update () {
		
	}
}
