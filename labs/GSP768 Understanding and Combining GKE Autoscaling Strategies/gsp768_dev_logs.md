


## Logs

* 2026-07-30 Ran into error when creating the demo-cluster.

	ChatGPT:   
	An INTERNAL (code 13) error is a generic GKE error. It could be caused by things such as:  
	```text
	Temporary Google Cloud backend issues
	Insufficient quota (CPUs, IP addresses, SSDs, etc.)
	IAM permission problems
	Invalid networking configuration
	Issues creating the default node pool
	```

	Error:  
	```text
	Note: Your Pod address range (`--cluster-ipv4-cidr`) can accommodate at most 1008 node(s).
	Creating cluster scaling-demo in us-east1-b... Cluster is being configured...done.                                                                                                            
	ERROR: (gcloud.container.clusters.create) Operation [<Operation
	clusterConditions: [<StatusCondition
	canonicalCode: CanonicalCodeValueValuesEnum(INTERNAL, 14)
	message: 'Failed to create cluster'>]
	detail: 'Failed to create cluster'
	endTime: '2026-07-30T18:41:58.403193853Z'
	error: <Status
	code: 13
	details: []
	message: 'Failed to create cluster'>
	name: 'operation-1785436853744-f94d016c-c678-4d9d-9f3c-6998165b7290'
	nodepoolConditions: []
	operationType: OperationTypeValueValuesEnum(CREATE_CLUSTER, 1)
	progress: <OperationProgress
	metrics: [<Metric
	intValue: 8
	name: 'CLUSTER_CONFIGURING'>, <Metric
	intValue: 8
	name: 'CLUSTER_CONFIGURING_TOTAL'>]
	stages: []>
	selfLink: 'https://container.googleapis.com/v1/projects/876843960036/zones/us-east1-b/operations/operation-1785436853744-f94d016c-c678-4d9d-9f3c-6998165b7290'
	startTime: '2026-07-30T18:40:53.744921514Z'
	status: StatusValueValuesEnum(DONE, 3)
	statusMessage: 'Failed to create cluster'
	targetLink: 'https://container.googleapis.com/v1/projects/876843960036/zones/us-east1-b/clusters/scaling-demo'
	zone: 'us-east1-b'>] finished with error: Failed to create cluster
	error: error validating "php-apache.yaml": error validating data: failed to download openapi: Get "http://localhost:8080/openapi/v2?timeout=32s": dial tcp 127.0.0.1:8080: connect: connection refused; if you choose to ignore these errors, turn validation off with --validate=false
	```