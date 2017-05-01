using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class NavigationDestination : MonoBehaviour {

    NavMeshAgent agent;

    public Vector3 destination;

	// Use this for initialization
	void Start () {
        agent = GetComponent<NavMeshAgent>();
        agent.SetDestination(destination);
        agent.updatePosition = false;
	}
	
	// Update is called once per frame
	void Update () {

        Vector3 nextPosition = Vector3.MoveTowards(transform.position, agent.steeringTarget, Time.deltaTime);

        transform.position = nextPosition;

        agent.nextPosition = nextPosition;

    }
}
