# Extend the Kubernetes API with CustomResourceDefinitions

> 1. 在后续的注释中，`<plural>` 表示 yaml 文件中 `plural` 声明的值。例如 `<plural>.<group>` 代表 string.concat(plural, '.', group)

## Create a CustomResourceDefinition

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
          # 声明一个类型为 object 的配置项并且这个 object 拥有唯一的一个 field ： spec
          type: object
          properties:
            spec:
              # 在 spec 下声明一个类型为 object 的配置项，配置项包含了 cronSpec, image, replicas 三个不同的 field
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

```bash
k create -f resource-definition.yaml

#查询我们的CRD
k get ct -o wide
#No resources found in default namespace.
```

> 同时我们还会得到一个全新的 api
>
> ```
> /apis/stable.example.com/v1/namespaces/*/crontabs/...
> ```

## managedFields

```bash
k explain cm.metadata.managedFields
```

>KIND:     ConfigMap
>VERSION:  v1
>
>RESOURCE: managedFields <[]Object>
>
>DESCRIPTION:
>ManagedFields maps workflow-id and version to the set of fields that are
>managed by that workflow. This is mostly for internal housekeeping, and
>users typically shouldn't need to set or understand this field. A workflow
>can be the user's name, a controller's name, or the name of a specific
>apply path like "ci-cd". The set of fields is always in the version that
>the workflow used when modifying the object.
>
>ManagedFieldsEntry is a workflow-id, a FieldSet and the group version of
>the resource that the fieldset applies to.
>
>FIELDS:
>apiVersion <string>
>APIVersion defines the version of this resource that this field set applies
>to. The format is "group/version" just like the top-level APIVersion field.
>It is necessary to track the version of a field set because it cannot be
>automatically converted.
>
>fieldsType <string>
>FieldsType is the discriminator for the different fields format and
>version. There is currently only one possible value: "FieldsV1"
>
>fieldsV1 <map[string]>
>FieldsV1 holds the first JSON version format as described in the "FieldsV1"
>type.
>
>manager  <string>
>Manager is an identifier of the workflow managing these fields.
>
>operation  <string>
>Operation is the type of operation which lead to this ManagedFieldsEntry
>being created. The only valid values for this field are 'Apply' and
>'Update'.
>
>subresource  <string>
>Subresource is the name of the subresource used to update that object, or
>empty string if the object was updated through the main resource. The value
>of this field is used to distinguish between managers, even if they share
>the same name. For example, a status update will be distinct from a regular
>update using the same manager name. Note that the APIVersion field is not
>related to the Subresource field and it always corresponds to the version
>of the main resource.
>
>time <string>
>Time is timestamp of when these fields were set. It should always be empty
>if Operation is 'Apply'

> 当我们执行 `k get ct -o yaml` 的时候，输出里会包含一个 `managedFields`字段，我们可以先了解一下这个字段是干什么的：
>
> 1. f 代表 field，它是字段名称
> 2. v 代表 value，它是字段值
> 3. k 代表 key，它是一个map对象，包含了字段名称和字段值
> 4. i 代表 index，它是数组的索引
>
> 除此之外还有几个关键字段：
>
> 1. **manager** ：指执行本次操作的主体。
> 2. **operation** ：指执行本次操作的类型。
> 3. **time** ：指执行本次操作的时间。

## Create custom objects

```yaml
apiVersion: "stable.example.com/v1"
kind: CronTab
metadata:
  name: my-new-cron-object
spec:
  cronSpec: "* * * * */5"
  image: my-awesome-cron-image
```

```bash
k apply -f my-crontab.yaml

k get ct -o yaml
```

```yaml
apiVersion: v1
items:
- apiVersion: stable.example.com/v1
  kind: CronTab
  metadata:
    annotations:
      kubectl.kubernetes.io/last-applied-configuration: |
        {"apiVersion":"stable.example.com/v1","kind":"CronTab","metadata":{"annotations":{},"name":"my-new-cron-object","namespace":"default"},"spec":{"cronSpec":"* * * * */5","image":"my-awesome-cron-image"}}
    creationTimestamp: "2021-11-17T12:20:57Z"
    generation: 1
    managedFields:
    - apiVersion: stable.example.com/v1
      fieldsType: FieldsV1
      fieldsV1:
        f:metadata:
          f:annotations:
            .: {}
            f:kubectl.kubernetes.io/last-applied-configuration: {}
        f:spec:
          .: {}
          f:cronSpec: {}
          f:image: {}
      manager: kubectl-client-side-apply
      operation: Update
      time: "2021-11-17T12:20:57Z"
    name: my-new-cron-object
    namespace: default
    resourceVersion: "33989"
    uid: 01691bb3-f03b-44b5-80d2-ac7aa5f01ba4
  spec:
    cronSpec: '* * * * */5'
    image: my-awesome-cron-image
kind: List
metadata:
  resourceVersion: ""
  selfLink: ""
```

## Specifying a structural schema

### [OpenAPI v3.0 validation schema](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#validation)

```yaml
        openAPIV3Schema:
          # 声明一个类型为 object 的配置项并且这个 object 拥有唯一的一个 field ： spec
          type: object
          properties:
            spec:
              # 在 spec 下声明一个类型为 object 的配置项，配置项包含了 cronSpec, image, replicas 三个不同的 field
              type: object
              properties:
                cronSpec:
                  type: string
                image:
                  type: string
                replicas:
                  type: integer
```

1. 为根节点type，对象的的每一个字段（properties 或 additionalProperties），数组的每个 item指定一个非空类型。以下情况例外：
   1. 指定 x-kubernetes-int-or-string: true
   2. 指定 x-kubernetes-preserve-unknown-fields: true
2. 对于声明在 `allOf`,`anyOf`,`oneOf`,`not`内的对象的每一个字段或者数组内的每一个item，schema 必须在 logic junctors 外声明。
3. 不在 `allOf`,`anyOf`,`oneOf`,`not`内设置description`, `type`, `default`, `additionalProperties`, `nullable。
   1. 规则3对于设置了 x-kubernetes-int-or-string: true 的情形例外
4. 如果`metadata`指定，则只允许限制`metadata.name`和`metadata.generateName`.

```yaml
allOf:
- properties:
    foo:
      ...
```

上面的声明违反了规则2，不合法，应该如下声明：

```yaml
properties:
  foo:
    ...
allOf:
- properties:
    foo:
      ...
```

以下的声明不合法：

```yaml
properties:
  foo:
    pattern: "abc"
  metadata:
    type: object
    properties:
      name:
        type: string
        pattern: "^a"
      finalizers:
        type: array
        items:
          type: string
          pattern: "my-finalizer"
anyOf:
- properties:
    bar:
      type: integer
      minimum: 42
  required: ["bar"]
  description: "foo bar object"
```

1. 不是以 type 作为根节点
2. foo 的 type 没有声明
3. 在 anyOf 中声明的 bar，必须先在外部声明
4. 不能在 anyOf 中声明 bar 的 type
5. 不能在 anyOf 中声明 description
6. `metadata.finalizers:` 可能不受限制（规则4）

正确的声明应该是

```yaml
type: object
description: "foo bar object"
properties:
  foo:
    type: string
    pattern: "abc"
  bar:
    type: integer
  metadata:
    type: object
    properties:
      name:
        type: string
        pattern: "^a"
anyOf:
- properties:
    bar:
      minimum: 42
  required: ["bar"]
```

## Field pruning

crd 将合法的资源数据存储在 etcd，如果我们声明了 api server 无法识别的字段，那么在存储到 etcd 之前这写无法识别的字段会被删除。

### Controlling pruning

> 通过配置 x-kubernetes-preserve-unknown-fields: true 可以保留 api server 无法识别的字段

```yaml
type: object
properties:
  json:
    x-kubernetes-preserve-unknown-fields: true
```

现在 json 可以存储任何值了

还可以指定 json 允许的类型，下面指定了 json 只允许 object 类型

```yaml
type: object
properties:
  json:
    x-kubernetes-preserve-unknown-fields: true
    type: object
    description: this is arbitrary JSON
```

`x-kubernetes-preserve-unknown-fields: true` 只在当前字段生效，对于内部声明的字段，pruning 会重新生效

```yaml
type: object
properties:
  json:
    x-kubernetes-preserve-unknown-fields: true
    type: object
    properties:
      spec:
        type: object
        properties:
          foo:
            type: string
          bar:
            type: string
```

上面的 yaml 表明，json 会保留所有的字段，而 json.spec 只会保留 foo 和 bar，下面的将会被 pruning

```yaml
json:
  spec:
    foo: abc
    bar: def
    something: x
  status:
    something: x
```

> 最后保留

```yaml
json:
  spec:
    foo: abc
    bar: def
  status:
    something: x
```

### IntOrString

Nodes in a schema with `x-kubernetes-int-or-string: true` are excluded from rule 1, such that the following is structural:

```yaml
type: object
properties:
  foo:
    x-kubernetes-int-or-string: true
```

## RawExtension

`apiVersion` 和 `kind` 声明在 RawExtensions 中（as in `runtime.RawExtension` defined in [k8s.io/apimachinery](https://github.com/kubernetes/apimachinery/blob/03ac7a9ade429d715a1a46ceaa3724c18ebae54f/pkg/runtime/types.go#L94)）

可以通过设置 `x-kubernetes-embedded-resource: true` 声明内置对象

```yaml
type: object
properties:
  foo:
    x-kubernetes-embedded-resource: true
    x-kubernetes-preserve-unknown-fields: true
```

Here, the field `foo` holds a complete object, e.g.:

```yaml
foo:
  apiVersion: v1
  kind: Pod
  spec:
    ...
```

With `x-kubernetes-embedded-resource: true`, the `apiVersion`, `kind` and `metadata` are implicitly specified and validated.

## Advanced topics

### Finalizers

> *Finalizers* allow controllers to implement asynchronous pre-delete hooks. Custom objects support finalizers similar to built-in objects.

```yaml
apiVersion: "stable.example.com/v1"
kind: CronTab
metadata:
  finalizers:
  - stable.example.com/finalizer
```

Identifiers of custom finalizers consist of a domain name, a forward slash and the name of the finalizer. Any controller can add a finalizer to any object's list of finalizers.

The first delete request on an object with finalizers sets a value for the `metadata.deletionTimestamp` field but does not delete it. Once this value is set, entries in the `finalizers` list can only be removed. While any finalizers remain it is also impossible to force the deletion of an object.

When the `metadata.deletionTimestamp` field is set, controllers watching the object execute any finalizers they handle and remove the finalizer from the list after they are done. It is the responsibility of each controller to remove its finalizer from the list.

The value of `metadata.deletionGracePeriodSeconds` controls the interval between polling updates.

Once the list of finalizers is empty, meaning all finalizers have been executed, the resource is deleted by Kubernetes.

### Validation

The schema is defined in the CustomResourceDefinition. In the following example, the CustomResourceDefinition applies the following validations on the custom object:

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: crontabs.stable.example.com
spec:
  group: stable.example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        # openAPIV3Schema is the schema for validating custom objects.
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                cronSpec:
                  type: string
                  pattern: '^(\d+|\*)(/\d+)?(\s+(\d+|\*)(/\d+)?){4}$'
                image:
                  type: string
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 10
  scope: Namespaced
  names:
    plural: crontabs
    singular: crontab
    kind: CronTab
    shortNames:
    - ct
```

A request to create a custom object of kind CronTab is rejected if there are invalid values in its fields. 

```yaml
#error-ct.yaml
apiVersion: "stable.example.com/v1"
kind: CronTab
metadata:
  name: my-new-cron-object
spec:
  cronSpec: "* * * *"
  image: my-awesome-cron-image
  replicas: 15
```

```bash
k apply -f error-ct.yaml

#The CronTab "my-new-cron-object" is invalid:
#* spec.cronSpec: Invalid value: "* * * *": spec.cronSpec in body should match '^(\d+|\*)(/\d+)?(\s+(\d+|\*)(/\d+)?){4}$'
#* spec.replicas: Invalid value: 15: spec.replicas in body should be less than or equal to 10
```

### Defaulting

> Defaulting allows to specify default values in the [OpenAPI v3 validation schema](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#validation):

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: crontabs.stable.example.com
spec:
  group: stable.example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        # openAPIV3Schema is the schema for validating custom objects.
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                cronSpec:
                  type: string
                  pattern: '^(\d+|\*)(/\d+)?(\s+(\d+|\*)(/\d+)?){4}$'
                  default: "5 0 * * *"
                image:
                  type: string
                replicas:
                  type: integer
                  minimum: 1
                  maximum: 10
                  default: 1
  scope: Namespaced
  names:
    plural: crontabs
    singular: crontab
    kind: CronTab
    shortNames:
    - ct
```

### Defaulting and Nullable

> null values for fields that either don't specify the nullable flag, or give it a `false` value, will be pruned before defaulting happens. If a default is present, it will be applied. When nullable is `true`, null values will be conserved and won't be defaulted.

```yaml
type: object
properties:
  spec:
    type: object
    properties:
      foo:
        type: string
        nullable: false
        default: "default"
      bar:
        type: string
        nullable: true
      baz:
        type: string
```

```yaml
spec:
  foo: null
  bar: null
  baz: null
```

leads to

```yaml
spec:
  foo: "default"
  bar: null
```

## Additional printer columns

The kubectl tool relies on server-side output formatting. Your cluster's API server decides which columns are shown by the `kubectl get` command. You can customize these columns for a CustomResourceDefinition. The following example adds the `Spec`, `Replicas`, and `Age` columns.

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: crontabs.stable.example.com
spec:
  group: stable.example.com
  scope: Namespaced
  names:
    plural: crontabs
    singular: crontab
    kind: CronTab
    shortNames:
    - ct
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              cronSpec:
                type: string
              image:
                type: string
              replicas:
                type: integer
    additionalPrinterColumns:
    - name: Spec
      type: string
      description: The cron spec defining the interval a CronJob is run
      jsonPath: .spec.cronSpec
    - name: Replicas
      type: integer
      description: The number of jobs launched by the CronJob
      jsonPath: .spec.replicas
    - name: Age
      type: date
      jsonPath: .metadata.creationTimestamp
```

```bash
kubectl get crontab my-new-cron-object

#NAME                 SPEC        REPLICAS   AGE
#my-new-cron-object   * * * * *   1          7s
```

> **Note:** The `NAME` column is implicit and does not need to be defined in the CustomResourceDefinition.

## Priority

- Columns with priority greater than `0` are shown only in wide view.
- Columns with priority `0` are shown in standard view.

## Type

A column's `type` field can be any of the following (compare [OpenAPI v3 data types](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md#dataTypes)):

- integer
- number
- string
- boolean
- date - rendered differentially as time since this timestamp.

## Subresources

Custom resources support `/status` and `/scale` subresources.

The status and scale subresources can be optionally enabled by defining them in the CustomResourceDefinition.

### Status subresource

### Scale subresource

When the scale subresource is enabled, the `/scale` subresource for the custom resource is exposed. 

- `specReplicasPath` defines the JSONPath inside of a custom resource that corresponds to `scale.spec.replicas`.
- `statusReplicasPath` defines the JSONPath inside of a custom resource that corresponds to `scale.status.replicas`.
- `labelSelectorPath` defines the JSONPath inside of a custom resource that corresponds to `Scale.Status.Selector`.

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: crontabs.stable.example.com
spec:
  group: stable.example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                cronSpec:
                  type: string
                image:
                  type: string
                replicas:
                  type: integer
            status:
              type: object
              properties:
                replicas:
                  type: integer
                labelSelector:
                  type: string
      # subresources describes the subresources for custom resources.
      subresources:
        # status enables the status subresource.
        status: {}
        # scale enables the scale subresource.
        scale:
          # specReplicasPath defines the JSONPath inside of a custom resource that corresponds to Scale.Spec.Replicas.
          specReplicasPath: .spec.replicas
          # statusReplicasPath defines the JSONPath inside of a custom resource that corresponds to Scale.Status.Replicas.
          statusReplicasPath: .status.replicas
          # labelSelectorPath defines the JSONPath inside of a custom resource that corresponds to Scale.Status.Selector.
          labelSelectorPath: .status.labelSelector
  scope: Namespaced
  names:
    plural: crontabs
    singular: crontab
    kind: CronTab
    shortNames:
    - ct
```

## Categories

Categories is a list of grouped resources the custom resource belongs to (eg. `all`). 

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: crontabs.stable.example.com
spec:
  group: stable.example.com
  versions:
    - name: v1
      served: true
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                cronSpec:
                  type: string
                image:
                  type: string
                replicas:
                  type: integer
  scope: Namespaced
  names:
    plural: crontabs
    singular: crontab
    kind: CronTab
    shortNames:
    - ct
    # categories is a list of grouped resources the custom resource belongs to.
    categories:
    - all
```

```bash
kubectl get all
#NAME                          AGE
#crontabs/my-new-cron-object   3s
```



































