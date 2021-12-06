# CRD

## reference

- [kubernetes operator tutorial](https://github.com/0x822a5b87/kubernetes-operator-test)
- [kubebuilder](https://github.com/kubernetes-sigs/kubebuilder)

- [operator sdk](https://sdk.operatorframework.io/)
- [Writing Your First Kubernetes Operator](https://faun.pub/writing-your-first-kubernetes-operator-8f3df4453234)
- [Go Operator Tutorial](https://sdk.operatorframework.io/docs/building-operators/golang/tutorial/)
- [kubernetes/sample-controller](https://github.com/kubernetes/sample-controller)

## tips

### 一些名词的的理解

> #### domain
>
> #### apiGroup
>
> 使用 `kubectl api-resources` 可以看到，有这些字段 `NAME	SHORTNAMES	APIGROUP	NAMESPACED	KIND`，有这两个我们比较熟悉的：
>
> - `NAME=pods,APIGROUP=''`
> - `NAME=deployments,APIGROUP=apps`
>
> 而在我们的 `yaml`文件中，则他们的 `apiVersion` 分别为
>
> 	- apiVersion: v1
> 	- apiVersion: apps/v1
>
> #### version

### operator api and controller

> operator 分为两个部分，分别是 api 和 controller，在使用 kubebuilder 或者 operator-sdk 创建 api 的时候一般会生成两个文件：
>
> - api/v1/xxx_types.go
> - controller/xxx_controller.go
>
> api 表明了 operator 的定义，元数据等；而 controller 决定了CRD的 `reconcile` 行为。

## CRD【CustomResourceDefinition】

> Operator=CRD+Controller
>
> CRD仅仅是资源的定义，而Controller可以去监听CRD的CRUD事件来添加自定义业务逻辑。

> - 下面定义了一个crd，简写为 `ct`；
> - crd 的 schema 的根目录是 一个 `spec:object`，包含了 `cronSpec:string`, `image:string`, `type:integer` 三个不同的类型；

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  # name must match the spec fields below, and be in the form: <plural>.<group>
  name: crontabs.stable.example.com
spec:
  # group name to use for REST API: /apis/<group>/<version>
  group: stable.example.com
  # list of versions supported by this CustomResourceDefinition
  versions:
    - name: v1
      # Each version can be enabled/disabled by Served flag.
      served: true
      # One and only one version must be marked as the storage version.
      storage: true
      schema:
        openAPIV3Schema:
          # schema 以 type: object 作为开头，因为我们的 yaml 文件就是一个 object
          type: object
          properties:
            # 声明一个 spec 字段
            spec:
              # spec 字段是 object 类型，包含了 cronSpec, image, replicas 三个不同的 field
              type: object
              properties:
                cronSpec:
                  type: string
                image:
                  type: string
                replicas:
                  type: integer
  # either Namespaced or Cluster
  scope: Namespaced
  names:
    # plural name to be used in the URL: /apis/<group>/<version>/<plural>
    plural: crontabs
    # singular name to be used as an alias on the CLI and for display
    singular: crontab
    # kind is normally the CamelCased singular type. Your resource manifests use this.
    kind: CronTab
    # shortNames allow shorter string to match your resource on the CLI
    shortNames:
    - ct
```

```yaml
# 初始化一个 ct
apiVersion: "stable.example.com/v1"
kind: CronTab
metadata:
  name: my-new-cron-object
spec:
  cronSpec: "* * * * */5"
  image: my-awesome-cron-image
```

### 查看 api resources 的属性

```bash
k api-resources
```

| NAME     | SHORTNAMES | APIGROUP           | NAMESPACED | KIND    |
| -------- | ---------- | ------------------ | ---------- | ------- |
| crontabs | ct         | stable.example.com | true       | CronTab |
| pods     | po         |                    | true       | Pod     |

## operator sdk

The following workflow is for a new [Go operator](https://sdk.operatorframework.io/docs/building-operators/golang/quickstart/):

1. Create a new operator project using the SDK Command Line Interface(CLI)
2. Define new resource APIs by adding Custom Resource Definitions(CRD)
3. Define Controllers to watch and reconcile resources
4. Write the reconciling logic for your Controller using the SDK and controller-runtime APIs
5. Use the SDK CLI to build and generate the operator deployment manifests

## kubebuilder

### 1. Tutorial: Building CronJob

#### 1.1 init

```bash
#--domain string            domain for groups (default "my.domain")
#--repo string              name to use for go module (e.g., github.com/user/repo), defaults to the go package of the current working directory.
kubebuilder init --domain tutorial.kubebuilder.io --repo tutorial.kubebuilder.io/project
```

####  1.2 Every journey needs a start, every program needs a main

```go
package main

import (
	"flag"
	"os"
	// Import all Kubernetes client auth plugins (e.g. Azure, GCP, OIDC, etc.)
	// to ensure that exec-entrypoint and run can make use of them.
	_ "k8s.io/client-go/plugin/pkg/client/auth"

	"k8s.io/apimachinery/pkg/runtime"
	utilruntime "k8s.io/apimachinery/pkg/util/runtime"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/healthz"
	"sigs.k8s.io/controller-runtime/pkg/log/zap"
	//+kubebuilder:scaffold:imports
)

var (
	// Scheme defines methods for serializing and deserializing API objects, a type
	// registry for converting group, version, and kind information to and from Go
	// schemas, and mappings between Go schemas of different versions. A scheme is the
	// foundation for a versioned API and versioned configuration over time.
	scheme   = runtime.NewScheme()
	setupLog = ctrl.Log.WithName("setup")
)

func init() {
	utilruntime.Must(clientgoscheme.AddToScheme(scheme))
}

func main() {
	// 解析参数，设置 prometheus 端口，健康检查端口，是否开启 leader 选举
	var metricsAddr string
	var enableLeaderElection bool
	var probeAddr string
	flag.StringVar(&metricsAddr, "metrics-bind-address", ":8080", "The address the metric endpoint binds to.")
	flag.StringVar(&probeAddr, "health-probe-bind-address", ":8081", "The address the probe endpoint binds to.")
	flag.BoolVar(&enableLeaderElection, "leader-elect", false,
		"Enable leader election for controller manager. "+
			"Enabling this will ensure there is only one active controller manager.")
	opts := zap.Options{
		Development: true,
	}
	opts.BindFlags(flag.CommandLine)
	flag.Parse()

	ctrl.SetLogger(zap.New(zap.UseFlagOptions(&opts)))

	// 初始化 Manager，它记录着我们所有控制器的运行情况，以及设置共享缓存和API服务器的客户端
	// Manager initializes shared dependencies such as Caches and Clients, and provides them to Runnable.
	// A Manager is required to create Controllers.
	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
		Scheme:                 scheme,
		MetricsBindAddress:     metricsAddr,
		Port:                   9443,
		HealthProbeBindAddress: probeAddr,
		LeaderElection:         enableLeaderElection,
		LeaderElectionID:       "80807133.tutorial.kubebuilder.io",
	})
	if err != nil {
		setupLog.Error(err, "unable to start manager")
		os.Exit(1)
	}

	if err := mgr.AddHealthzCheck("healthz", healthz.Ping); err != nil {
		setupLog.Error(err, "unable to set up health check")
		os.Exit(1)
	}
	if err := mgr.AddReadyzCheck("readyz", healthz.Ping); err != nil {
		setupLog.Error(err, "unable to set up ready check")
		os.Exit(1)
	}

	// 执行 Manager
	setupLog.Info("starting manager")
	if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil {
		setupLog.Error(err, "problem running manager")
		os.Exit(1)
	}
}
```

#### 1.3 Groups, Kinds and Versions

>--group 对应 crd.spec.group
>
>--version 对应 crd.spec.versions
>
>--kind 对应 crd.spec.names.kind

> Basically, the CRDs are a definition of our customized Objects, and the CRs are an instance of it.

- An *API Group* in Kubernetes is simply a collection of related functionality.
- Each group has one or more *versions*
- Each API group-version contains one or more API types, which we call *Kinds*.
- A resource is simply a use of a Kind in the API.For instance, the `pods` resource corresponds to the `Pod` Kind.

##### scheme

> **The `Scheme` we saw before is simply a way to keep track of what Go type corresponds to a given GVK**

#### 1.4 Adding a new API

```bash
kubebuilder create api --group batch --version v1 --kind CronJob
```

生成的 PROEJCT 文件如下

```
domain: tutorial.kubebuilder.io
layout:
- go.kubebuilder.io/v3
projectName: kubebuildertutorial
repo: tutorial.kubebuilder.io/project
resources:
- api:
    crdVersion: v1
    namespaced: true
  controller: true
  domain: tutorial.kubebuilder.io
  group: batch
  kind: CronJob
  path: tutorial.kubebuilder.io/project/api/v1
  version: v1
version: "3"
```

> Kubernetes functions by reconciling desired state (`Spec`) with actual cluster state (other objects’ `Status`) and external state, and then recording what it observed (`Status`). Thus, every *functional* object includes spec and status. A few types, like `ConfigMap` don’t follow this pattern, since they don’t encode desired state, but most types do.

```go
package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// CronJob 期待的状态
type CronJobSpec struct {
	Foo string `json:"foo,omitempty"`
}

// CronJob 实际的状态
type CronJobStatus struct {
}
```

> Next, we define the types corresponding to actual Kinds, `CronJob` and `CronJobList`. `CronJob` is our root type, and describes the `CronJob` kind. Like all Kubernetes objects, it contains `TypeMeta` (which describes API version and Kind), and also contains `ObjectMeta`, which holds things like name, namespace, and labels.
>
> `CronJobList` is simply a container for multiple `CronJob`s. It’s the Kind used in bulk operations, like LIST.

```go

// 定义 cronjobs 的 schema
type CronJob struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   CronJobSpec   `json:"spec,omitempty"`
	Status CronJobStatus `json:"status,omitempty"`
}

// CronJob 列表
type CronJobList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []CronJob `json:"items"`
}
// 注册
func init() {
	SchemeBuilder.Register(&CronJob{}, &CronJobList{})
}
```

此时我们已经可以看到我们创建的 crd 了

| NAME       | SHORTNAMES | APIGROUP           | NAMESPACED | KIND      |
| ---------- | ---------- | ------------------ | ---------- | --------- |
| guestbooks | ct         | webapp.hangyudu.io | false      | Guestbook |

#### 1.5 Designing an API

> - ConcurrencyPolicy 任务并行执行策略
> - Suspend 允许用户手动停止任务
> - SuccessfulJobsHistoryLimit 和 FailedJobsHistoryLimit 表示对旧的历史任务的限制。

```go
// CronJobSpec defines the desired state of CronJob
type CronJobSpec struct {
	//+kubebuilder:validation:MinLength=0

	// The schedule in Cron format, see https://en.wikipedia.org/wiki/Cron.
	Schedule string `json:"schedule"`

	//+kubebuilder:validation:Minimum=0

	// Optional deadline in seconds for starting the job if it misses scheduled
	// time for any reason.  Missed jobs executions will be counted as failed ones.
	// +optional
	StartingDeadlineSeconds *int64 `json:"startingDeadlineSeconds,omitempty"`

	// Specifies how to treat concurrent executions of a Job.
	// Valid values are:
	// - "Allow" (default): allows CronJobs to run concurrently;
	// - "Forbid": forbids concurrent runs, skipping next run if previous run hasn't finished yet;
	// - "Replace": cancels currently running job and replaces it with a new one
	// +optional
	ConcurrencyPolicy ConcurrencyPolicy `json:"concurrencyPolicy,omitempty"`

	// This flag tells the controller to suspend subsequent executions, it does
	// not apply to already started executions.  Defaults to false.
	// +optional
	Suspend *bool `json:"suspend,omitempty"`

	// Specifies the job that will be created when executing a CronJob.
	JobTemplate batchv1beta1.JobTemplateSpec `json:"jobTemplate"`

	//+kubebuilder:validation:Minimum=0

	// The number of successful finished jobs to retain.
	// This is a pointer to distinguish between explicit zero and not specified.
	// +optional
	SuccessfulJobsHistoryLimit *int32 `json:"successfulJobsHistoryLimit,omitempty"`

	//+kubebuilder:validation:Minimum=0

	// The number of failed finished jobs to retain.
	// This is a pointer to distinguish between explicit zero and not specified.
	// +optional
	FailedJobsHistoryLimit *int32 `json:"failedJobsHistoryLimit,omitempty"`
}
```

> Status

```go
// CronJobStatus defines the observed state of CronJob
type CronJobStatus struct {
    // INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
    // Important: Run "make" to regenerate code after modifying this file

    // A list of pointers to currently running jobs.
    // +optional
    Active []corev1.ObjectReference `json:"active,omitempty"`

    // Information when was the last time the job was successfully scheduled.
    // +optional
    LastScheduleTime *metav1.Time `json:"lastScheduleTime,omitempty"`
}
```

#### 1.6 what's in a controller?

> It’s a controller’s job to ensure that, for any given object, the actual state of the world (both the cluster state, and potentially external state like running containers for Kubelet or loadbalancers for a cloud provider) matches the desired state in the object. Each controller focuses on one *root* Kind, but may interact with other Kinds.
>
> **We call this process `reconciling`.**
>
> In controller-runtime, the logic that implements the reconciling for a specific kind is called a [*Reconciler*](https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/reconcile?tab=doc). A reconciler takes the name of an object, and returns whether or not we need to try again

```go
// CronJobReconciler reconciles a CronJob object
type CronJobReconciler struct {
    // kubernetes controller-runtime client
	client.Client
	Log    logr.Logger
    // kubernetes apimachinery scheme
	Scheme *runtime.Scheme
}

//  do reconciler
func (r *CronJobReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	_ = context.Background()
	_ = r.Log.WithValues("cronjob", req.NamespacedName)

	// your logic here

	return ctrl.Result{}, nil
}

// setup manager
func (r *CronJobReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&batchv1.CronJob{}).
		Complete(r)
}
```

#### 1.7 implementing a controller

> Load the CronJob by name

```go
	/*
		### 1: Load the CronJob by name

		We'll fetch the CronJob using our client.  All client methods take a
		context (to allow for cancellation) as their first argument, and the object
		in question as their last.  Get is a bit special, in that it takes a
		[`NamespacedName`](https://pkg.go.dev/sigs.k8s.io/controller-runtime/pkg/client?tab=doc#ObjectKey)
		as the middle argument (most don't have a middle argument, as we'll see
		below).

		Many client methods also take variadic options at the end.
	*/
	var cronJob batchv1.CronJob
	if err := r.Get(ctx, req.NamespacedName, &cronJob); err != nil {
		log.Error(err, "unable to fetch CronJob")
		// we'll ignore not-found errors, since they can't be fixed by an immediate
		// requeue (we'll need to wait for a new notification), and we can get them
		// on deleted requests.
		return ctrl.Result{}, client.IgnoreNotFound(err)
	}
```

> List all active jobs, and update the status

```go
	/*
		### 2: List all active jobs, and update the status

		To fully update our status, we'll need to list all child jobs in this namespace that belong to this CronJob.
		Similarly to Get, we can use the List method to list the child jobs.  Notice that we use variadic options to
		set the namespace and field match (which is actually an index lookup that we set up below).
	*/
	var childJobs kbatch.JobList
	if err := r.List(ctx, &childJobs, client.InNamespace(req.Namespace), client.MatchingFields{jobOwnerKey: req.Name}); err != nil {
		log.Error(err, "unable to list child Jobs")
		return ctrl.Result{}, err
	}
```

##### What is this index about?

> The reconciler fetches all jobs owned by the cronjob for the status. As our number of cronjobs increases, looking these up can become quite slow as we have to filter through all of them. For a more efficient lookup, these jobs will be indexed locally on the controller's name. A jobOwnerKey field is added to the cached job objects. This key references the owning controller and functions as the index. Later in this document we will configure the manager to actually index this field.

> Once we have all the jobs we own, we’ll split them into active, successful, and failed jobs, keeping track of the most recent run so that we can record it in status. Remember, status should be able to be reconstituted from the state of the world, so it’s generally not a good idea to read from the status of the root object. Instead, you should reconstruct it every run. That’s what we’ll do here.

```go
	// find the active list of jobs
	var activeJobs []*kbatch.Job
	var successfulJobs []*kbatch.Job
	var failedJobs []*kbatch.Job
	var mostRecentTime *time.Time // find the last run so we can update the status

	/*
		We consider a job "finished" if it has a "Complete" or "Failed" condition marked as true.
		Status conditions allow us to add extensible status information to our objects that other
		humans and controllers can examine to check things like completion and health.
	*/
	isJobFinished := func(job *kbatch.Job) (bool, kbatch.JobConditionType) {
		for _, c := range job.Status.Conditions {
			if (c.Type == kbatch.JobComplete || c.Type == kbatch.JobFailed) && c.Status == corev1.ConditionTrue {
				return true, c.Type
			}
		}

		return false, ""
	}
	// +kubebuilder:docs-gen:collapse=isJobFinished

	/*
		We'll use a helper to extract the scheduled time from the annotation that
		we added during job creation.
	*/
	getScheduledTimeForJob := func(job *kbatch.Job) (*time.Time, error) {
		timeRaw := job.Annotations[scheduledTimeAnnotation]
		if len(timeRaw) == 0 {
			return nil, nil
		}

		timeParsed, err := time.Parse(time.RFC3339, timeRaw)
		if err != nil {
			return nil, err
		}
		return &timeParsed, nil
	}
	// +kubebuilder:docs-gen:collapse=getScheduledTimeForJob

	for i, job := range childJobs.Items {
		_, finishedType := isJobFinished(&job)
		switch finishedType {
		case "": // ongoing
			activeJobs = append(activeJobs, &childJobs.Items[i])
		case kbatch.JobFailed:
			failedJobs = append(failedJobs, &childJobs.Items[i])
		case kbatch.JobComplete:
			successfulJobs = append(successfulJobs, &childJobs.Items[i])
		}

		// We'll store the launch time in an annotation, so we'll reconstitute that from
		// the active jobs themselves.
		scheduledTimeForJob, err := getScheduledTimeForJob(&job)
		if err != nil {
			log.Error(err, "unable to parse schedule time for child job", "job", &job)
			continue
		}
		if scheduledTimeForJob != nil {
			if mostRecentTime == nil {
				mostRecentTime = scheduledTimeForJob
			} else if mostRecentTime.Before(*scheduledTimeForJob) {
				mostRecentTime = scheduledTimeForJob
			}
		}
	}

	if mostRecentTime != nil {
		cronJob.Status.LastScheduleTime = &metav1.Time{Time: *mostRecentTime}
	} else {
		cronJob.Status.LastScheduleTime = nil
	}
	cronJob.Status.Active = nil
	for _, activeJob := range activeJobs {
		jobRef, err := ref.GetReference(r.Scheme, activeJob)
		if err != nil {
			log.Error(err, "unable to make reference to active job", "job", activeJob)
			continue
		}
		cronJob.Status.Active = append(cronJob.Status.Active, *jobRef)
	}
```

```go
	/*
		Here, we'll log how many jobs we observed at a slightly higher logging level,
		for debugging.  Notice how instead of using a format string, we use a fixed message,
		and attach key-value pairs with the extra information.  This makes it easier to
		filter and query log lines.
	*/
	log.V(1).Info("job count", "active jobs", len(activeJobs), "successful jobs", len(successfulJobs), "failed jobs", len(failedJobs))

	/*
		Using the date we've gathered, we'll update the status of our CRD.
		Just like before, we use our client.  To specifically update the status
		subresource, we'll use the `Status` part of the client, with the `Update`
		method.

		The status subresource ignores changes to spec, so it's less likely to conflict
		with any other updates, and can have separate permissions.
	*/
	if err := r.Status().Update(ctx, &cronJob); err != nil {
		log.Error(err, "unable to update CronJob status")
		return ctrl.Result{}, err
	}
```

> Once we’ve updated our status, we can move on to ensuring that the status of the world matches what we want in our spec.
>
> **3: Clean up old jobs according to the history limit**
>
> First, we'll try to clean up old jobs, so that we don't leave too many lying around.

```go
	if cronJob.Spec.FailedJobsHistoryLimit != nil {
		sort.Slice(failedJobs, func(i, j int) bool {
			if failedJobs[i].Status.StartTime == nil {
				return failedJobs[j].Status.StartTime != nil
			}
			return failedJobs[i].Status.StartTime.Before(failedJobs[j].Status.StartTime)
		})
		for i, job := range failedJobs {
			if int32(i) >= int32(len(failedJobs))-*cronJob.Spec.FailedJobsHistoryLimit {
				break
			}
			if err := r.Delete(ctx, job, client.PropagationPolicy(metav1.DeletePropagationBackground)); client.IgnoreNotFound(err) != nil {
				log.Error(err, "unable to delete old failed job", "job", job)
			} else {
				log.V(0).Info("deleted old failed job", "job", job)
			}
		}
	}

	if cronJob.Spec.SuccessfulJobsHistoryLimit != nil {
		sort.Slice(successfulJobs, func(i, j int) bool {
			if successfulJobs[i].Status.StartTime == nil {
				return successfulJobs[j].Status.StartTime != nil
			}
			return successfulJobs[i].Status.StartTime.Before(successfulJobs[j].Status.StartTime)
		})
		for i, job := range successfulJobs {
			if int32(i) >= int32(len(successfulJobs))-*cronJob.Spec.SuccessfulJobsHistoryLimit {
				break
			}
			if err := r.Delete(ctx, job, client.PropagationPolicy(metav1.DeletePropagationBackground)); (err) != nil {
				log.Error(err, "unable to delete old successful job", "job", job)
			} else {
				log.V(0).Info("deleted old successful job", "job", job)
			}
		}
	}
```

> **4: Check if we are suspend**
>
> If this object is suspended, we don’t want to run any jobs, so we’ll stop now. This is useful if something’s broken with the job we’re running and we want to pause runs to investigate or putz with the cluster, without deleting the object.

```go
	if cronJob.Spec.Suspend != nil && *cronJob.Spec.Suspend {
		log.V(1).Info("cronjob suspended, skipping")
		return ctrl.Result{}, nil
	}
```

> **5: Get the next scheduled run**
>
> If we’re not paused, we’ll need to calculate the next scheduled run, and whether or not we’ve got a run that we haven’t processed yet.

```go
	/*
		We'll calculate the next scheduled time using our helpful cron library.
		We'll start calculating appropriate times from our last run, or the creation
		of the CronJob if we can't find a last run.

		If there are too many missed runs and we don't have any deadlines set, we'll
		bail so that we don't cause issues on controller restarts or wedges.

		Otherwise, we'll just return the missed runs (of which we'll just use the latest),
		and the next run, so that we can know when it's time to reconcile again.
	*/
	getNextSchedule := func(cronJob *batchv1.CronJob, now time.Time) (lastMissed time.Time, next time.Time, err error) {
		sched, err := cron.ParseStandard(cronJob.Spec.Schedule)
		if err != nil {
			return time.Time{}, time.Time{}, fmt.Errorf("Unparseable schedule %q: %v", cronJob.Spec.Schedule, err)
		}

		// for optimization purposes, cheat a bit and start from our last observed run time
		// we could reconstitute this here, but there's not much point, since we've
		// just updated it.
		var earliestTime time.Time
		if cronJob.Status.LastScheduleTime != nil {
			earliestTime = cronJob.Status.LastScheduleTime.Time
		} else {
			earliestTime = cronJob.ObjectMeta.CreationTimestamp.Time
		}
		if cronJob.Spec.StartingDeadlineSeconds != nil {
			// controller is not going to schedule anything below this point
			schedulingDeadline := now.Add(-time.Second * time.Duration(*cronJob.Spec.StartingDeadlineSeconds))

			if schedulingDeadline.After(earliestTime) {
				earliestTime = schedulingDeadline
			}
		}
		if earliestTime.After(now) {
			return time.Time{}, sched.Next(now), nil
		}

		starts := 0
		for t := sched.Next(earliestTime); !t.After(now); t = sched.Next(t) {
			lastMissed = t
			// An object might miss several starts. For example, if
			// controller gets wedged on Friday at 5:01pm when everyone has
			// gone home, and someone comes in on Tuesday AM and discovers
			// the problem and restarts the controller, then all the hourly
			// jobs, more than 80 of them for one hourly scheduledJob, should
			// all start running with no further intervention (if the scheduledJob
			// allows concurrency and late starts).
			//
			// However, if there is a bug somewhere, or incorrect clock
			// on controller's server or apiservers (for setting creationTimestamp)
			// then there could be so many missed start times (it could be off
			// by decades or more), that it would eat up all the CPU and memory
			// of this controller. In that case, we want to not try to list
			// all the missed start times.
			starts++
			if starts > 100 {
				// We can't get the most recent times so just return an empty slice
				return time.Time{}, time.Time{}, fmt.Errorf("Too many missed start times (> 100). Set or decrease .spec.startingDeadlineSeconds or check clock skew.")
			}
		}
		return lastMissed, sched.Next(now), nil
	}
```

```go
	// figure out the next times that we need to create
	// jobs at (or anything we missed).
	missedRun, nextRun, err := getNextSchedule(&cronJob, r.Now())
	if err != nil {
		log.Error(err, "unable to figure out CronJob schedule")
		// we don't really care about requeuing until we get an update that
		// fixes the schedule, so don't return an error
		return ctrl.Result{}, nil
	}

	/*
		We'll prep our eventual request to requeue until the next job, and then figure
		out if we actually need to run.
	*/
	scheduledResult := ctrl.Result{RequeueAfter: nextRun.Sub(r.Now())} // save this so we can re-use it elsewhere
	log = log.WithValues("now", r.Now(), "next run", nextRun)
```

> **6: Run a new job if it's on schedule, not past the deadline, and not blocked by our concurrency policy**

> If we've missed a run, and we're still within the deadline to start it, we'll need to run a job.

```go
    if missedRun.IsZero() {
        log.V(1).Info("no upcoming scheduled times, sleeping until next")
        return scheduledResult, nil
    }

    // 确保错过的执行没有超过截止时间
    log = log.WithValues("current run", missedRun)
    tooLate := false
    if cronJob.Spec.StartingDeadlineSeconds != nil {
        tooLate = missedRun.Add(time.Duration(*cronJob.Spec.StartingDeadlineSeconds) * time.Second).Before(r.Now())
    }
    if tooLate {
        log.V(1).Info("missed starting deadline for last run, sleeping till next")
        // TODO(directxman12): events
        return scheduledResult, nil
    }
```

>If we actually have to run a job, we’ll need to either wait till existing ones finish, replace the existing ones, or just add new ones. If our information is out of date due to cache delay, we’ll get a requeue when we get up-to-date information.

```go
    // figure out how to run this job -- concurrency policy might forbid us from running
    // multiple at the same time...
    if cronJob.Spec.ConcurrencyPolicy == batchv1.ForbidConcurrent && len(activeJobs) > 0 {
        log.V(1).Info("concurrency policy blocks concurrent runs, skipping", "num active", len(activeJobs))
        return scheduledResult, nil
    }

    // ...or instruct us to replace existing ones...
    if cronJob.Spec.ConcurrencyPolicy == batchv1.ReplaceConcurrent {
        for _, activeJob := range activeJobs {
            // we don't care if the job was already deleted
            if err := r.Delete(ctx, activeJob, client.PropagationPolicy(metav1.DeletePropagationBackground)); client.IgnoreNotFound(err) != nil {
                log.Error(err, "unable to delete active job", "job", activeJob)
                return ctrl.Result{}, err
            }
        }
    }
```

> Once we’ve figured out what to do with existing jobs, we’ll actually create our desired job

```go
    // actually make the job...
    job, err := constructJobForCronJob(&cronJob, missedRun)
    if err != nil {
        log.Error(err, "unable to construct job from template")
        // don't bother requeuing until we get a change to the spec
        return scheduledResult, nil
    }

    // ...and create it on the cluster
    if err := r.Create(ctx, job); err != nil {
        log.Error(err, "unable to create Job for CronJob", "job", job)
        return ctrl.Result{}, err
    }

    log.V(1).Info("created Job for CronJob run", "job", job)
```

> **7: Requeue when we either see a running job or it's time for the next scheduled run**

## Go Operator Tutorial

### Create a new project

```bash
operator-sdk init --domain example.com --repo github.com/example/memcached-operator

operator-sdk create api --group cache --version v1alpha1 --kind Memcached --resource --controller
```

### Define the API

> To begin, we will represent our API by defining the `Memcached` type, which will have a `MemcachedSpec.Size` field to set the quantity of memcached instances (CRs) to be deployed, and a `MemcachedStatus.Nodes` field to store a CR’s Pod names.
>
> **Note** The Node field is just to illustrate an example of a Status field. In real cases, it would be recommended to use [Conditions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#typical-status-properties).
>
> ```go
> 	isJobFinished := func(job *kbatch.Job) (bool, kbatch.JobConditionType) {
> 		for _, c := range job.Status.Conditions {
> 			if (c.Type == kbatch.JobComplete || c.Type == kbatch.JobFailed) && c.Status == corev1.ConditionTrue {
> 				return true, c.Type
> 			}
> 		}
> 
> 		return false, ""
> 	}
> ```
>
> Define the API for the Memcached Custom Resource(CR) by modifying the Go type definitions at `api/v1alpha1/memcached_types.go` to have the following spec and status:

```go
// MemcachedSpec defines the desired state of Memcached
type MemcachedSpec struct {
	//+kubebuilder:validation:Minimum=0
	// Size is the size of the memcached deployment
	Size int32 `json:"size"`
}

// MemcachedStatus defines the observed state of Memcached
type MemcachedStatus struct {
	// Nodes are the names of the memcached pods
	Nodes []string `json:"nodes"`
}
```

### Implement the Controller

#### Resources watched by the Controller

> The `SetupWithManager()` function in `controllers/memcached_controller.go` specifies how the controller is built to watch a CR and other resources that are owned and managed by that controller.

```go
// SetupWithManager sets up the controller with the Manager.
func (r *MemcachedReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&cachev1alpha1.Memcached{}).
		Complete(r)
}
```

>`Owns(&appsv1.Deployment{})` specifies the Deployments type as the `secondary` resource to watch. For each Deployment type Add/Update/Delete event, the event handler will map each event to a reconcile `Request` for the owner of the Deployment. Which in this case is the Memcached object for which the Deployment was created.

```go
// SetupWithManager sets up the controller with the Manager.
func (r *MemcachedReconciler) SetupWithManager(mgr ctrl.Manager) error {
   return ctrl.NewControllerManagedBy(mgr).
      For(&cachev1alpha1.Memcached{}).
      Owns(&appsv1.Deployment{}).
      Complete(r)
}
```

#### Reconcile loop

> The reconcile function is responsible for enforcing the desired CR state on the actual state of the system. It runs each time an event occurs on a watched CR or resource, and will return some value depending on whether those states match or not.

```Go
import (
	ctrl "sigs.k8s.io/controller-runtime"

	cachev1alpha1 "github.com/example/memcached-operator/api/v1alpha1"
	...
)

func (r *MemcachedReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
  // Lookup the Memcached instance for this reconcile request
  memcached := &cachev1alpha1.Memcached{}
  err := r.Get(ctx, req.NamespacedName, memcached)
  ...
}
```

The following are a few possible return options for a Reconciler:

 ```go
 // With the error:
 return ctrl.Result{}, err
 
 // Without an error:
 return ctrl.Result{Requeue: true}, nil
 
 // Therefore, to stop the Reconcile, use:
 return ctrl.Result{}, nil
 
 // Reconcile again after X time:
  return ctrl.Result{RequeueAfter: nextRun.Sub(r.Now())}, nil
 ```

## Writing Your First Kubernetes Operator

```bash
operator-sdk init --domain app.example.com --repo tutorial.operatorsdk.io/podset

operator-sdk create api --group batch --version v1 --kind PodSet --resource --controller
```

> 可以看到在 `config/samples/batch_v1_podset.yaml` 中生成了如下的 yaml。
>
> 其中 `apiVersion` 由 `api-resources 的 APIGROUP` + `domain` + "/" + `version` 得到

```yaml
apiVersion: batch.app.example.com/v1
kind: PodSet
metadata:
  name: podset-sample
spec:
  # Add fields here
```

### Podset_types.go

```go
// PodSetSpec defines the desired state of PodSet
type PodSetSpec struct {
	// 副本数量
	Replicas int32 `json:"replicas"`
}

// PodSetStatus defines the observed state of PodSet
type PodSetStatus struct {
	PodNames []string `json:"podNames"`
}
```

### resoureces

> Then, we need to configure the primary and secondary resources that the controller will monitor in the namespace. For our PodSet operator, the primary resource is the PodSet resource and the secondary resources are the pods in the namespace.

### Reconcile

> 1. The reconcile function is invoked each time the PodSet resource is changed or a change happens in the pods belonging to the PodSet.
> 2. If pods need to be added or removed, the `Reconcile` function should only add or remove one pod at a time, return, and wait for the next invocation (since it will be called after a pod was created or deleted).
> 3. Make sure that the pods are “owned” by the PodSet primary resource using the `controllerutil.SetControllerReference()` function. Having this ownership in place means that when the PodSet resource is deleted, all its “child” pods are deleted as well.

### run

```bash
make manifests

make install
```

### check

```bash
k api-resources --api-group=batch.app.example.com
#NAME      SHORTNAMES   APIGROUP                NAMESPACED   KIND
#podsets                batch.app.example.com   true         PodSet
```

### podset_controller.go

```go
/*
Copyright 2021.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/apimachinery/pkg/runtime"
	"reflect"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	logf "sigs.k8s.io/controller-runtime/pkg/log"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"
	"time"
	batchv1 "tutorial.operatorsdk.io/podset/api/v1"
)

var log = logf.Log.WithName("controller_podset")

// PodSetReconciler reconciles a PodSet object
type PodSetReconciler struct {
	client.Client
	Scheme *runtime.Scheme
}

//+kubebuilder:rbac:groups=batch.app.example.com,resources=podsets,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=batch.app.example.com,resources=podsets/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=batch.app.example.com,resources=podsets/finalizers,verbs=update

// Reconcile reads that state of the cluster for a PodSet object and makes changes based on the state read
// and what is in the PodSet.Spec
// a Pod as an example
// Note:
// The Controller will requeue the Request to be processed again if the returned error is non-nil or
// Result.Requeue is true, otherwise upon completion it will remove the work from the queue.

func (r *PodSetReconciler) Reconcile(ctx context.Context, request reconcile.Request) (reconcile.Result, error) {
	reqLogger := log.WithValues("Request.Namespace", request.Namespace, "Request.Name", request.Name)
	reqLogger.Info("Reconciling PodSet")

	// 获取当前 PodSet
	podSet := batchv1.PodSet{}
	err := r.Get(ctx, request.NamespacedName, &podSet)
	if err != nil {
		if errors.IsNotFound(err) {
			return reconcile.Result{}, nil
		}
		return reconcile.Result{}, err
	}

	// 获取当前 Pod 状态，并和实预期的状态做对比
	existingPods := &corev1.PodList{}
	podLabels := labels.Set{
		"app":     podSet.Name,
		"version": "v1.0",
	}
	err = r.List(ctx, existingPods, &client.ListOptions{
		LabelSelector: labels.SelectorFromSet(podLabels),
		Namespace:     podSet.Namespace,
	})
	if err != nil {
		reqLogger.Error(err, "error get pods : ",
			"request.Namespace", request.Namespace, "matchingFields", podLabels)

		return reconcile.Result{}, err
	}
	var existingPodNames []string
	for _, pod := range existingPods.Items {
		if pod.GetObjectMeta().GetDeletionTimestamp() != nil {
			continue
		}
		if pod.Status.Phase == corev1.PodPending || pod.Status.Phase == corev1.PodRunning {
			existingPodNames = append(existingPodNames, pod.Name)
		}
	}
	status := batchv1.PodSetStatus{
		Replicas: int32(len(existingPodNames)),
		PodNames: existingPodNames,
	}
	if !reflect.DeepEqual(podSet.Status, status) {
		podSet.Status = status
		err := r.Client.Status().Update(context.TODO(), &podSet)
		if err != nil {
			reqLogger.Error(err, "failed to update the podSet")
			return reconcile.Result{}, err
		}
	}

	// 缩容
	if status.Replicas > podSet.Spec.Replicas {
		reqLogger.Info("delete a pod in the podset", "expected replicas", podSet.Spec.Replicas, "Pod.Names", existingPodNames)
		pod := existingPods.Items[0]
		err = r.Delete(ctx, &pod)
		if err != nil {
			reqLogger.Error(err, "error delete pods!")
			return reconcile.Result{}, err
		}
	}

	// 扩容
	if status.Replicas < podSet.Spec.Replicas {
		reqLogger.Info("Adding a pod in the podset", "expected replicas", podSet.Spec.Replicas, "Pod.Names", existingPodNames)
		pod := newPodForCR(&podSet)
		if err := controllerutil.SetControllerReference(&podSet, pod, r.Scheme); err != nil {
			reqLogger.Error(err, "unable to set owner reference on new pod")
			return reconcile.Result{}, err
		}
		err = r.Create(ctx, pod)
		if err != nil {
			reqLogger.Error(err, "error create pods!")
			return reconcile.Result{}, err
		}
	}

	return reconcile.Result{Requeue: true}, err
}

func newPodForCR(ps *batchv1.PodSet) *corev1.Pod {
	podLabels := map[string]string{
		"app":     ps.Name,
		"version": "v1.0",
	}

	return &corev1.Pod{
		ObjectMeta: metav1.ObjectMeta{
			GenerateName:      ps.Name + "-pod",
			Namespace:         ps.Namespace,
			CreationTimestamp: metav1.NewTime(time.Now()),
			Labels:            podLabels,
		},
		Spec: corev1.PodSpec{
			Containers: []corev1.Container{
				{
					Name:  "busybox",
					Image: "busybox",
					Command: []string{
						"sleep", "3600",
					},
				},
			},
		},
	}
}

// SetupWithManager sets up the controller with the Manager.
func (r *PodSetReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&batchv1.PodSet{}).
		Owns(&corev1.Pod{}).
		Complete(r)
}
```











































