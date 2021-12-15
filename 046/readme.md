### helm

## reference

[helm document](https://helm.sh/zh/docs/)

## 安装Helm

> 下载 helm 并配置环境变量

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

## 使用Helm

### 三大概念

>Helm 安装 *charts* 到 Kubernetes 集群中，每次安装都会创建一个新的 *release*。你可以在 Helm 的 chart *repositories* 中寻找新的 chart。

- *Chart* 代表着 Helm 包。它包含在 Kubernetes 集群内部运行应用程序，工具或服务所需的所有资源定义。你可以把它看作是 Homebrew formula，Apt dpkg，或 Yum RPM 在Kubernetes 中的等价物。
- *Repository（仓库）* 是用来存放和共享 charts 的地方。它就像 Perl 的 [CPAN 档案库网络](https://www.cpan.org/) 或是 Fedora 的 [软件包仓库](https://src.fedoraproject.org/)，只不过它是供 Kubernetes 包所使用的。
- *Release* 是运行在 Kubernetes 集群中的 chart 的实例。一个 chart 通常可以在同一个集群中安装多次。每一次安装都会创建一个新的 *release*。以 MySQL chart为例，如果你想在你的集群中运行两个数据库，你可以安装该chart两次。每一个数据库都会拥有它自己的 *release* 和 *release name*。

### helm 目录结构

>一个Charts就是按特定格式组织的目录结构，目录名即为Charts名，目录名称本身不包含版本信息。目录结构中除了charts/和templates/是目录之外，其他的都是文件。它们的基本功用如下。

- Chart.yaml：当前Charts的描述信息，yaml格式的文件。
- values.yaml：当前Charts用到的默认配置值。
- charts/：目录，存放当前Charts依赖到的所有Charts文件。
- templates/：目录，存放当前Charts用到的模板文件，可应用于Charts生成有效的Kubernetes清单文件。
  - deployment.yaml
  - service.yaml
  - ingress.yaml
  - ...
- LICENSE：当前Charts的许可证信息，纯文本文件；此为可选文件。
- README.md：易读格式的README文件；可选。
- requirements.yaml：当前Charts的依赖关系描述文件；可选。
- templates/NOTES.txt：纯文本文件，Templates简单使用注解

> 尽管Charts和Templates目录均为可选，但至少应该存在一个Charts依赖文件或一个模板文件。另外，Helm保留使用charts/和templates/目录以及上面列出的文件名称，其他文件都将被忽略。

### 'helm search'：查找 Charts

```bash
# 从 Artifact Hub 中查找并列出 helm charts
helm search hub

# 查找 hub 下的 wordpress
helm search hub wordpress

# 从你添加（使用 helm repo add）到本地 helm 客户端中的仓库中进行查找。该命令基于本地数据进行搜索，无需连接互联网。
helm search repo

# 搜索所有add的repo下的mysql
helm search repo wordpress
```

```bash
# 列出所有 repo
helm repo list
#NAME   	URL
#bitnami	https://charts.bitnami.com/bitnami
```

### 'helm install'：安装一个 helm 包

> 使用 `helm install` 命令来安装一个新的 helm 包。最简单的使用方法只需要传入两个参数：你命名的release名字和你想安装的chart的名称。

```bash
# 安装 wordpress，并命名为 happy-panda
helm install happy-panda bitnami/wordpress

k get svc -o wide
# 打开本地端口访问
minikube service happy-panda --url
```

### 安装前自定义 chart

```bash
# 查看 charm 中的可配置项
helm show values bitnami/wordpress

# 可以使用 YAML 格式的文件覆盖上述任意配置项，并在安装过程中使用该文件
echo '{mariadb.auth.database: user0db, mariadb.auth.username: user0}' > values.yaml
helm install -f values.yaml bitnami/wordpress --generate-name
```

```yaml
## @section Global parameters
## Global Docker image parameters
## Please, note that this will override the image parameters, including dependencies, configured to use the global value
## Current available global Docker image parameters: imageRegistry, imagePullSecrets and storageClass

## @param global.imageRegistry Global Docker image registry
## @param global.imagePullSecrets Global Docker registry secret names as an array
## @param global.storageClass Global StorageClass for Persistent Volume(s)
##
global:
  imageRegistry: ""
  ## E.g.
  ## imagePullSecrets:
  ##   - myRegistryKeySecretName
  ##
  imagePullSecrets: []
  storageClass: ""
#...
mariadb:
  ## @param mariadb.enabled Deploy a MariaDB server to satisfy the applications database requirements
  ## To use an external database set this to false and configure the `externalDatabase.*` parameters
  ##
  enabled: true
  ## @param mariadb.architecture MariaDB architecture. Allowed values: `standalone` or `replication`
  ##
  architecture: standalone
  ## MariaDB Authentication parameters
  ## @param mariadb.auth.rootPassword MariaDB root password
  ## @param mariadb.auth.database MariaDB custom database
  ## @param mariadb.auth.username MariaDB custom user name
  ## @param mariadb.auth.password MariaDB custom user password
  ## ref: https://github.com/bitnami/bitnami-docker-mariadb#setting-the-root-password-on-first-run
  ##      https://github.com/bitnami/bitnami-docker-mariadb/blob/master/README.md#creating-a-database-on-first-run
  ##      https://github.com/bitnami/bitnami-docker-mariadb/blob/master/README.md#creating-a-database-user-on-first-run
  auth:
    rootPassword: ""
    database: bitnami_wordpress
    username: bn_wordpress
    password: ""
  ## MariaDB Primary configuration
  ##
#...
```

安装过程中有两种方式传递配置数据：

- `--values` (或 `-f`)：使用 YAML 文件覆盖配置。可以指定多次，优先使用最右边的文件。
- `--set`：通过命令行的方式对指定项进行覆盖。

如果同时使用两种方式，则 `--set` 中的值会被合并到 `--values` 中，但是 `--set` 中的值优先级更高。在`--set` 中覆盖的内容会被被保存在 ConfigMap 中。可以通过 `helm get values <release-name>` 来查看指定 release 中 `--set` 设置的值。也可以通过运行 `helm upgrade` 并指定 `--reset-values` 字段来清除 `--set` 中设置的值。

```bash
helm get values wordpress-1639203677
#USER-SUPPLIED VALUES:
#mariadb.auth.database: user0db
#mariadb.auth.username: user0
```

### 更多安装方法

`helm install` 命令可以从多个来源进行安装：

- chart 的仓库（如上所述）
- 本地 chart 压缩包（`helm install foo foo-0.1.1.tgz`）
- 解压后的 chart 目录（`helm install foo path/to/foo`）
- 完整的 URL（`helm install foo https://example.com/charts/foo-1.2.3.tgz`）

### 'helm upgrade' 和 'helm rollback'：升级 release 和失败时恢复

> 当你想升级到 chart 的新版本，或是修改 release 的配置，你可以使用 `helm upgrade` 命令。

> helm只会更新自上次发布以来发生了更改的内容

``` bash
helm upgrade -f panda.yaml happy-panda bitnami/wordpress
```

> 现在，假如在一次发布过程中，发生了不符合预期的事情，也很容易通过 `helm rollback [RELEASE] [REVISION]` 命令回滚到之前的发布版本。

```bash
helm rollback happy-panda 1
```

上面这条命令将我们的 `happy-panda` 回滚到了它最初的版本。release 版本其实是一个增量修订（revision）。 每当发生了一次安装、升级或回滚操作，revision 的值就会加1。第一次 revision 的值永远是1。我们可以使用 `helm history [RELEASE]` 命令来查看一个特定 release 的修订版本号。

> 可以查看某一个特定版本的配置

```bash
helm get values --revision=1 wordpress-1639203677
```

### 安装、升级、回滚时的有用选项

- `--timeout`：一个 [Go duration](https://golang.org/pkg/time/#ParseDuration) 类型的值， 用来表示等待 Kubernetes 命令完成的超时时间，默认值为 `5m0s`。
- `--wait`：表示必须要等到所有的 Pods 都处于 ready 状态，PVC 都被绑定，Deployments 都至少拥有最小 ready 状态 Pods 个数（`Desired`减去 `maxUnavailable`），并且 Services 都具有 IP 地址（如果是`LoadBalancer`， 则为 Ingress），才会标记该 release 为成功。
- `--no-hooks`：不运行当前命令的钩子。

### 'helm uninstall'：卸载 release

```bash
helm uninstall happy-panda
```

### 'helm repo'：使用仓库

```bash
# 配置仓库
helm repo add stable https://burdenbear.github.io/kube-charts-mirror

# 查看仓库
helm repo list

# 更新仓库
helm repo update

# 删除仓库
helm repo remove
```

### 创建你自己的 charts

> [chart 开发指南](https://helm.sh/zh/docs/topics/charts) 介绍了如何开发你自己的chart。 但是你也可以通过使用 `helm create` 命令来快速开始：

```bash
helm create deis-workflow

# 检查格式是否正确
helm lint

# 打包分发 Chart
helm package deis-workflow

# 安装我们的 Chart
helm install deis-workflow ./deis-workflow-0.1.0.tgz
```

## chart开发提示和技巧

### 了解你的模板功能

> Helm使用了 [Go模板](https://godoc.org/text/template)将你的自由文件构建成模板。 Go塑造了一些内置方法，我们增加了一些其他的。

> 首先，我们添加了 [Sprig库](https://masterminds.github.io/sprig/)中所有的方法，出于安全原因，“env”和“expandenv”除外。
>
> 我们也添加了两个特殊的模板方法：`include`和`required`。

> `include`方法允许你引入另一个模板，并将结果传递给其他模板方法。

比如，这个模板片段将 `dot` 引入并命名为 mytpl，然后将其转成小写，并使用双引号括起来。

```go
value: {{ include "mytpl" . | lower | quote }}
```

> `required`方法可以让你声明模板渲染所需的特定值。如果这个值是空的，模板渲染会出错并打印用户提交的错误信息。

下面这个`required`方法的例子声明了一个`.Values.who`需要的条目，并且当这个条目不存在时会打印错误信息：

```go
value: {{ required "A valid .Values.who entry required!" .Values.who }}
```

### 字符串引号括起来，但整型不用

> 使用字符串数据时，你总是更安全地将字符串括起来而不是露在外面：

```go
name: {{ .Values.MyName | quote }}
```

> 但是使用整型时 *不要把值括起来*。在很多场景中那样会导致Kubernetes内解析失败。

```go
port: {{ .Values.Port }}
```

### 使用'include'方法

```go
{{ include "toYaml" $value | indent 2 }}
```

上面这个包含的模板称为`toYaml`，传值给`$value`，然后将这个模板的输出传给`indent`方法。

### 使用 'required' 方法

> `required`方法允许开发者声明一个模板渲染需要的值。如果在`values.yaml`中这个值是空的，模板就不会渲染并返回开发者提供的错误信息。

```go
{{ required "A valid foo is required!" .Values.foo }}
```

上述示例表示当`.Values.foo`被定义时模板会被渲染，但是未定义时渲染会失败并退出。

### 使用'tpl'方法

> tpl`方法允许开发者在模板中使用字符串作为模板。将模板字符串作为值传给chart或渲染额外的配置文件时会很有用。 语法： `{{ tpl TEMPLATE_STRING VALUES }}

```go
# values
template: "{{ .Values.name }}"
name: "Tom"

# template
{{ tpl .Values.template . }}

# output
Tom
```

额外的渲染配置文件

```go
# external configuration file conf/app.conf
firstName={{ .Values.firstName }}
lastName={{ .Values.lastName }}

# values
firstName: Peter
lastName: Parker

# template
{{ tpl (.Files.Get "conf/app.conf") . }}

# output
firstName=Peter
lastName=Parker
```

### 创建镜像拉取密钥

> 镜像拉取密钥本质上是 *注册表*， *用户名* 和 *密码* 的组合。

首先，假定`values.yaml`文件中定义了证书如下：

```yaml
imageCredentials:
  registry: quay.io
  username: someone
  password: sillyness
  email: someone@host.com
```

然后定义下面的辅助模板：

```go
{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}
```

最终，我们使用辅助模板在更大的模板中创建了密钥清单：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: myregistrykey
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: {{ template "imagePullSecret" . }}
```

### 自动滚动部署

> 由于配置映射或密钥作为配置文件注入容器以及其他外部依赖更新导致经常需要滚动部署pod。 随后的`helm upgrade`更新基于这个应用可能需要重新启动，但如果负载本身没有更改并使用原有配置保持运行，会导致部署不一致。

`sha256sum`方法保证在另一个文件发生更改时更新负载说明：

```yaml
kind: Deployment
spec:
  template:
    metadata:
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
[...]
```

注意：如果要将这些添加到库chart中，就无法使用`$.Template.BasePath`访问你的文件。相反你可以使用 `{{ include ("mylibchart.configmap") . | sha256sum }}` 引用你的定义。

这个场景下你通常想滚动更新你的负载，可以使用类似的说明步骤，而不是使用随机字符串替换，因而经常更改并导致负载滚动更新：

```yaml
kind: Deployment
spec:
  template:
    metadata:
      annotations:
        rollme: {{ randAlphaNum 5 | quote }}
[...]
```

每次调用模板方法会生成一个唯一的随机字符串。这意味着如果需要同步多种资源使用的随机字符串，所有的相对资源都要在同一个模板文件中。

这两种方法都允许你的部署利用内置的更新策略逻辑来避免停机。

### 告诉Helm不要卸载资源

有时在执行`helm uninstall`时有些资源不应该被卸载。Chart的开发者可以在资源中添加额外的说明避免被卸载。

```yaml
kind: Secret
metadata:
  annotations:
    "helm.sh/resource-policy": keep
[...]
```

这个说明`"helm.sh/resource-policy": keep`指示Helm操作(比如`helm uninstall`，`helm upgrade` 或`helm rollback`)要删除时跳过删除这个资源，*然而*，这个资源会变成孤立的。Helm不再以任何方式管理它。 如果在已经卸载的但保留资源的版本上使用`helm install --replace`会出问题。

### 使用"Partials"和模板引用

有时你想在chart中创建可以重复利用的部分，不管是块还是局部模板。通常将这些文件保存在自己的文件中会更干净。

在`templates/`目录中，任何以下划线(`_`)开始的文件不希望输出到Kubernetes清单文件中。因此按照惯例，辅助模板和局部模板会被放在`_helpers.tpl`文件中。

### 使用很多依赖的复杂Chart

当前从离散组件组成一个复杂应用的最佳实践是创建一个顶层总体chart构建全局配置，然后使用`charts/`子目录嵌入每个组件。

## Chart发布操作用以自动化GitHub的页面Chart

>该指南描述了如何使用 [Chart发布操作](https://github.com/marketplace/actions/helm-chart-releaser) 通过GitHub页面自动发布chart。Chart发布操作是一个将GitHub项目转换成自托管Helm chart仓库的GitHub操作流。使用了 [helm/chart-releaser](https://github.com/helm/chart-releaser) CLI 工具。

### 操作

```bash
git clone https://github.com/0x822a5b87/test-chart-release.git

cd test-chart-release

helm create .
```

## chart

>该文档解释说明了chart格式，并提供了用Helm构建chart的基本指导。

Helm使用的包格式称为 *chart*。 chart就是一个描述Kubernetes相关资源的文件集合。单个chart可以用来部署一些简单的， 类似于memcache pod，或者某些复杂的HTTP服务器以及web全栈应用、数据库、缓存等等。

### Chart 文件结构

> chart是一个组织在文件目录中的集合。目录名称就是chart名称（没有版本信息）。因而描述WordPress的chart可以存储在`wordpress/`目录中。

在这个目录中，Helm 期望可以匹配以下结构：

```
wordpress/
  Chart.yaml          # 包含了chart信息的YAML文件
  LICENSE             # 可选: 包含chart许可证的纯文本文件
  README.md           # 可选: 可读的README文件
  values.yaml         # chart 默认的配置值
  values.schema.json  # 可选: 一个使用JSON结构的values.yaml文件
  charts/             # 包含chart依赖的其他chart
  crds/               # 自定义资源的定义
  templates/          # 模板目录， 当和values 结合时，可生成有效的Kubernetes manifest文件
  templates/NOTES.txt # 可选: 包含简要使用说明的纯文本文件
```

### Chart.yaml 文件

```yaml
apiVersion: chart API 版本 （必需）
name: chart名称 （必需）
version: 语义化2 版本（必需）
kubeVersion: 兼容Kubernetes版本的语义化版本（可选）
description: 一句话对这个项目的描述（可选）
type: chart类型 （可选）
keywords:
  - 关于项目的一组关键字（可选）
home: 项目home页面的URL （可选）
sources:
  - 项目源码的URL列表（可选）
dependencies: # chart 必要条件列表 （可选）
  - name: chart名称 (nginx)
    version: chart版本 ("1.2.3")
    repository: （可选）仓库URL ("https://example.com/charts") 或别名 ("@repo-name")
    condition: （可选） 解析为布尔值的yaml路径，用于启用/禁用chart (e.g. subchart1.enabled )
    tags: # （可选）
      - 用于一次启用/禁用 一组chart的tag
    import-values: # （可选）
      - ImportValue 保存源值到导入父键的映射。每项可以是字符串或者一对子/父列表项
    alias: （可选） chart中使用的别名。当你要多次添加相同的chart时会很有用
maintainers: # （可选）
  - name: 维护者名字 （每个维护者都需要）
    email: 维护者邮箱 （每个维护者可选）
    url: 维护者URL （每个维护者可选）
icon: 用做icon的SVG或PNG图片URL （可选）
appVersion: 包含的应用版本（可选）。不需要是语义化，建议使用引号
deprecated: 不被推荐的chart （可选，布尔值）
annotations:
  example: 按名称输入的批注列表 （可选）.
```

#### Chart和版本控制

> 每个chart都必须有个版本号。版本必须遵循 [语义化版本 2](https://semver.org/spec/v2.0.0.html) 标准。 不像经典Helm， Helm v2以及后续版本会使用版本号作为发布标记。仓库中的包通过名称加版本号标识。

比如 `nginx` chart的版本字段`version: 1.2.3`按照名称被设置为：

```
nginx-1.2.3.tgz
```

#### `kubeVersion` 字段

> 可选的 `kubeVersion` 字段可以在支持的Kubernetes版本上定义语义化版本约束，Helm 在安装chart时会验证这个版本约束， 并在集群运行不支持的Kubernetes版本时显示失败。

```yaml
# 版本约束可以包括空格分隔和比较运算符
kubeVersion: >= 1.13.0 < 1.15.0

# 或者它们可以用或操作符 || 连接，比如：
kubeVersion: >= 1.13.0 < 1.14.0 || >= 1.14.1 < 1.15.0
```

#### Chart Types

> `type`字段定义了chart的类型。有两种类型： `application` 和 `library`。 应用是默认类型，是可以完全操作的标准chart。 [库类型 chart](https://www.bookstack.cn/read/helm-3.7.1-zh/f3f0a05a1bde5886.md) 提供针对chart构建的实用程序和功能。 库类型chart与应用类型chart不同，因为它不能安装，通常不包含任何资源对象。

### Chart 许可证，自述和注释

chart也会包含一个简短的纯文本 `templates/NOTES.txt` 文件，这会在安装后及查看版本状态时打印出来。 这个文件会作为一个 [模板](https://www.bookstack.cn/read/helm-3.7.1-zh/1289ac082c9bef7d.md#templates-and-values)来评估，并用来显示使用说明，后续步骤，或者其他chart版本的相关信息。 比如，可以提供连接数据库的说明，web UI的访问。由于此文件是在运行`helm install`或`helm status`时打印到STDOUT的， 因此建议保持内容简短，并指向自述文件以获取更多详细信息。

### Chart dependency

> Helm 中，chart可能会依赖其他任意个chart。 这些依赖可以使用`Chart.yaml`文件中的`dependencies` 字段动态链接，或者被带入到`charts/` 目录并手动配置。

#### 使用 `dependencies` 字段管理依赖

```yaml
dependencies:
  - name: apache
    version: 1.2.3
    repository: https://example.com/charts
  - name: mysql
    version: 3.2.1
    repository: https://another.example.com/charts
```

你可以使用仓库的名称代替URL，但是记得：

1. 使用 `""`
2. 使用 `@` 解引用

```bash
$ helm repo add fantastic-charts https://fantastic-charts.storage.googleapis.com
```

```yaml
dependencies:
  - name: awesomeness
    version: 1.0.0
    # 使用 @ 来进行解引用
    repository: "@fantastic-charts"
```

一旦你定义好了依赖，运行 `helm dependency update` 就会使用你的依赖文件下载所有你指定的chart到你的`charts/`目录。

#### 依赖中的tag和条件字段

> 除了上面的其他字段外，每个需求项可以包含可选字段 `tags` 和 `condition`。
>
> 所有的chart会默认加载。如果存在 `tags` 或者 `condition` 字段，它们将被评估并用于控制它们应用的chart的加载。

#### 通过依赖导入子Value

>如果子chart的`values.yaml`文件中在根节点包含了`exports`字段，它的内容可以通过指定的可以被直接导入到父chart的value中， 如下所示：

```yaml
# parent's Chart.yaml file
dependencies:
  - name: subchart
    repository: http://localhost:10191
    version: 0.1.0
    import-values:
      - data
```

```yaml
# child's values.yaml file
exports:
  data:
    myint: 99
```

### Templates and Values

> Helm Chart 模板是按照 [Go模板语言](https://golang.org/pkg/text/template/)书写， 增加了50个左右的附加模板函数 [来自 Sprig库](https://github.com/Masterminds/sprig) 和一些其他 [指定的函数](https://www.bookstack.cn/read/helm-3.7.1-zh/ef5ffe344fb86414.md)。
>
> 所有模板文件存储在chart的 `templates/` 文件夹。 当Helm渲染chart时，它会通过模板引擎遍历目录中的每个文件。

模板的Value通过两种方式提供：

- Chart开发者可以在chart中提供一个命名为 `values.yaml` 的文件。这个文件包含了默认值。
- Chart用户可以提供一个包含了value的YAML文件。可以在命令行使用 `helm install`命令时提供。

> 当用户提供自定义value时，这些value会覆盖chart的`values.yaml`文件中value。

#### 模板文件

>模板文件遵守书写Go模板的标准惯例（查看 [文本/模板 Go 包文档](https://golang.org/pkg/text/template/)了解更多）。 模板文件的例子看起来像这样：

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: deis-database
  namespace: deis
  labels:
    app.kubernetes.io/managed-by: deis
spec:
  replicas: 1
  selector:
    app.kubernetes.io/name: deis-database
  template:
    metadata:
      labels:
        app.kubernetes.io/name: deis-database
    spec:
      serviceAccount: deis-database
      containers:
        - name: deis-database
          image: {{ .Values.imageRegistry }}/postgres:{{ .Values.dockerTag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
          ports:
            - containerPort: 5432
          env:
            - name: DATABASE_STORAGE
              value: {{ default "minio" .Values.storage }}
```

> 可以使用下面四种模板值（一般被定义在`values.yaml`文件）：

#### 预定义的Values

> Values通过模板中`.Values`对象可访问的`values.yaml`文件（或者通过 `--set` 参数)提供， 但可以模板中访问其他预定义的数据片段。

- `Release.Name`: 版本名称(非chart的)
- `Release.Namespace`: 发布的chart版本的命名空间
- `Release.Service`: 组织版本的服务
- ...

#### Values文件

考虑到前面部分的模板，`values.yaml`文件提供的必要值如下：

```yaml
imageRegistry: "quay.io/deis"
dockerTag: "latest"
pullPolicy: "Always"
storage: "s3"
```

values文件被定义为YAML格式。chart会包含一个默认的`values.yaml`文件。 Helm安装命令允许用户使用附加的YAML values覆盖这个values：

```bash
helm install --generate-name --values=myvals.yaml wordpress
```

以这种方式传递值时，它们会合并到默认的values文件中。比如，`myvals.yaml`文件如下：

```yaml
storage: "gcs"
```

最后生成

```yaml
imageRegistry: "quay.io/deis"
dockerTag: "latest"
pullPolicy: "Always"
storage: "gcs"
```

#### 范围，依赖和值

> 上面提到的 WordPress，它有两个依赖的 chart，分别是 mysql 和 apache，values 文件可以为以下所有组件提供依赖

```yaml
title:"My WordPress Site"# Sent to the WordPress template
mysql:
  max_connections:100# Sent to MySQL
  password:"secret"
apache:
  port:8080# Passed to Apache
```

更高阶的chart可以访问下面定义的所有变量。因此WordPress chart可以用`.Values.mysql.password`访问MySQL密码。 但是低阶的chart不能访问父级chart，所以MySQL无法访问`title`属性。同样也无法访问`apache.port`。

Values 被限制在命名空间中，但是命名空间被删减了。因此对于WordPress chart， 它可以用`.Values.mysql.password`访问MySQL的密码字段。但是对于MySQL chart，值的范围被缩减了且命名空间前缀被移除了， 因此它把密码字段简单地看作`.Values.password`。

##### 全局Values

```yaml
title: "My WordPress Site"# Sent to the WordPress template
global:
  app: MyWordPress
mysql:
  max_connections: 100# Sent to MySQL
  password: "secret"
apache:
  port: 8080# Passed to Apache
```

实际上，上面的values文件会重新生成为这样：

```yaml
title: "My WordPress Site"# Sent to the WordPress template
global:
  app: MyWordPress
mysql:
global:
    app: MyWordPress
  max_connections: 100# Sent to MySQL
  password: "secret"
apache:
global:
    app: MyWordPress
  port: 8080# Passed to Apache
```

> 父chart的全局变量优先于子chart中的全局变量。

### 用户自定义资源(CRD)

> Helm 3中,CRD被视为一种特殊的对象。它们被安装在chart的其他部分之前，并受到一些限制。

CRD 文件 *无法模板化*，必须是普通的YAML文档。

#### CRD的限制

>不像大部分的Kubernetes对象，CRD是全局安装的。因此Helm管理CRD时会采取非常谨慎的方式。 CRD受到以下限制：

- CRD从不重新安装。 如果Helm确定`crds/`目录中的CRD已经存在（忽略版本），Helm不会安装或升级。
- CRD从不会在升级或回滚时安装。Helm只会在安装时创建CRD。
- CRD从不会被删除。自动删除CRD会删除集群中所有命名空间中的所有CRD内容。因此Helm不会删除CRD。

### Chart仓库

> *chart仓库* 是一个HTTP服务器，包含了一个或多个打包的chart。当`helm`用来管理本地chart目录时， 共享chart时，首选的机制就是使用chart仓库。

## Chart Hook

>Helm 提供了一个 *hook* 机制允许chart开发者在发布生命周期的某些点进行干预。

### 可用的钩子

| 注释值          | 描述                                                         |
| :-------------- | :----------------------------------------------------------- |
| `pre-install`   | 在模板渲染之后，Kubernetes资源创建之前执行                   |
| `post-install`  | 在所有资源加载到Kubernetes之后执行                           |
| `pre-delete`    | 在Kubernetes删除之前，执行删除请求                           |
| `post-delete`   | 在所有的版本资源删除之后执行删除请求                         |
| `pre-upgrade`   | 在模板渲染之后，资源更新之前执行一个升级请求                 |
| `post-upgrade`  | 所有资源升级之后执行一个升级请求                             |
| `pre-rollback`  | 在模板渲染之后，资源回滚之前，执行一个回滚请求               |
| `post-rollback` | 在所有资源被修改之后执行一个回滚请求                         |
| `test`          | 调用Helm test子命令时执行 ( [test文档](https://www.bookstack.cn/read/helm-3.7.1-zh/c776287cbc7b2564.md)) |

### 编写一个钩子

> 钩子就是在`metadata`部分指定了特殊注释的Kubernetes清单文件。比如这个模板，存储在`templates/post-install-job.yaml`，声明了一个要运行在`post-install`上的任务。

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ .Release.Name }}"
  labels:
    app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
    app.kubernetes.io/instance: {{ .Release.Name | quote }}
    app.kubernetes.io/version: {{ .Chart.AppVersion }}
    helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
  annotations:
    # This is what defines this resource as a hook. Without this line, the
    # job is considered part of the release.
    "helm.sh/hook": post-install
    "helm.sh/hook-weight": "-5"
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    metadata:
      name: "{{ .Release.Name }}"
      labels:
        app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
        app.kubernetes.io/instance: {{ .Release.Name | quote }}
        helm.sh/chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    spec:
      restartPolicy: Never
      containers:
      - name: post-install-job
        image: "alpine:3.3"
        command: ["/bin/sleep","{{ default "10" .Values.sleepyTime }}"]
```

使模板称为钩子的是注释：

```yaml
annotations:
  "helm.sh/hook": post-install
```

一个资源可以实现多个钩子：

```yaml
annotations:
  "helm.sh/hook": post-install,post-upgrade
```

可以为钩子定义权重，这有助于建立一个确定性的执行顺序。权重使用以下注释定义：

```yaml
annotations:
  "helm.sh/hook-weight": "5"
```

### Chart Test

#### Example Test

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami

helm pull bitnami/wordpress --untar
```

在`wordpress/templates/tests/test-mariadb-connection.yaml`中，会看到一个test，可以试试：

> 在下面的例子中，我们可以看到很多的特殊点：
>
> - {{ .Release.Name }} helm 预定义引用
> - {{ template "wordpress.image" . }} 引用 wordpress.image 模板。在 charts/values.yaml 中声明了 `image:`，而它会自动的注册成一个 template。
> - {{ template "mariadb.fullname" . }} 引用 mariadb.fullname 模板
>
> 这里需要注意的是，模板 `"wordpress.image"` 定义在 wordpress/templates/_helpers.tpl 中；
>
> 在 charts/mariadb/values.yaml 中能找到对 `mariadb.fullname` 模板的声明；
>
> **但是，按照 helm 的模板规则，所有以下划线开始的文件(_)不会输出到Kubernetes清单文件中。**

```yaml
{{- if .Values.mariadb.enabled }}
apiVersion: v1
kind: Pod
metadata:
  name: "{{ .Release.Name }}-credentials-test"
  annotations:
    # 钩子的定义
    "helm.sh/hook": test
spec:
  containers:
    - name: {{ .Release.Name }}-credentials-test
      image: {{ template "wordpress.image" . }}
      imagePullPolicy: {{ .Values.image.pullPolicy | quote }}
      {{- if .Values.securityContext.enabled }}
      securityContext:
        runAsUser: {{ .Values.securityContext.runAsUser }}
      {{- end }}
      env:
        - name: MARIADB_HOST
          value: {{ template "mariadb.fullname" . }}
        - name: MARIADB_PORT
          value: "3306"
        - name: WORDPRESS_DATABASE_NAME
          value: {{ default "" .Values.mariadb.db.name | quote }}
        - name: WORDPRESS_DATABASE_USER
          value: {{ default "" .Values.mariadb.db.user | quote }}
        - name: WORDPRESS_DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ template "mariadb.fullname" . }}
              key: mariadb-password
      command:
        - /bin/bash
        - -ec
        - |
                    mysql --host=$MARIADB_HOST --port=$MARIADB_PORT --user=$WORDPRESS_DATABASE_USER --password=$WORDPRESS_DATABASE_PASSWORD
  restartPolicy: Never
{{- end }}
```

## 库类型Chart

### 创建一个简单的库chart

```bash
helm create mylibchart

#本示例中创建自己的模板需要先删除templates目录中的所有文件。
rm -rf mylibchart/templates/*
#不再需要values文件。
rm -f mylibchart/values.yaml

#编辑模板
vim mylibchart/templates/_configmap.yaml
```

```yaml
{{- define "mylibchart.configmap.tpl" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name | printf "%s-%s" .Chart.Name }}
data: {}
{{- end -}}
{{- define "mylibchart.configmap" -}}
{{- include "mylibchart.util.merge" (append . "mylibchart.configmap.tpl") -}}
{{- end -}}
```

这个配置映射结构被定义在名为`mylibchart.configmap.tpl`的模板文件中。`data`是一个空源的配置映射， 这个文件中另一个命名的模板是`mylibchart.configmap`。这个模板包含了另一个模板`mylibchart.util.merge`， 会使用两个命名的模板作为参数，称为`mylibchart.configmap`和`mylibchart.configmap.tpl`。

复制方法`mylibchart.util.merge`是`mylibchart/templates/_util.yaml`文件中的一个命名模板。 是 [通用Helm辅助Chart](https://www.bookstack.cn/read/helm-3.7.1-zh/f3f0a05a1bde5886.md#the-common-helm-helper-chart)的实用工具。因为它合并了两个模板并覆盖了两个模板的公共部分。

```go
{{- /*
mylibchart.util.merge will merge two YAML templates and output the result.
This takes an array of three values:
- the top context
- the template name of the overrides (destination)
- the template name of the base (source)
*/}}
{{- define "mylibchart.util.merge" -}}
{{- $top := first . -}}
{{- $overrides := fromYaml (include (index . 1) $top) | default (dict ) -}}
{{- $tpl := fromYaml (include (index . 2) $top) | default (dict ) -}}
{{- toYaml (merge $overrides $tpl) -}}
{{- end -}}
```

最后，将chart类型修改为`library`。需要按以下方式编辑`mylibchart/Chart.yaml`：

```yaml
apiVersion: v2
name: mylibchart
description: A Helm chart for Kubernetes
# A chart can be either an 'application' or a 'library' chart.
#
# Application charts are a collection of templates that can be packaged into versioned archives
# to be deployed.
#
# Library charts provide useful utilities or functions for the chart developer. They're included as
# a dependency of application charts to inject those utilities and functions into the rendering
# pipeline. Library charts do not define any templates and therefore cannot be deployed.
# type: application
type: library
# This is the chart version. This version number should be incremented each time you make changes
# to the chart and its templates, including the app version.
version: 0.1.0
# This is the version number of the application being deployed. This version number should be
# incremented each time you make changes to the application and it is recommended to use it with quotes.
appVersion: "1.16.0"
```

### 使用简单的库chart

```bash
helm create mychart

rm -rf mychart/templates/*
```

## values

### 命名规范

> 变量名称以小写字母开头，单词按驼峰区分：

### 扁平或嵌套的Value

```yaml
#嵌套的
server:
  name: nginx
  port: 80

#扁平的
serverName: nginx
serverPort: 80
```

大多数场景中，扁平的优于嵌套的。因为对模板开发者和用户来说更加简单。

### 搞清楚类型

避免类型强制规则错误最简单的方式是字符串明确定义，其他都是不明确的。或者，简单来讲， *给所有字符串打引号*。

通常，为了避免整数转换问题，将整型存储为字符串更好，并用 `{{ int $value }}` 在模板中将字符串转回整型。

### 考虑用户如何使用你的value

有三种潜在的value来源:

- chart的`values.yaml`文件
- 由`helm install -f` 或 `helm upgrade -f`提供的values文件
- 在执行`helm install` 或 `helm upgrade` 时传递给`--set` 或 `--set-string` 参数的values

> 使用map构建values文件更好。

```yaml
servers:
  - name: foo
    port: 80
  - name: bar
    port: 81
```

上述在Helm `<=2.4`的版本中无法和`--set`一起表达。在Helm 2.5中，访问foo上的端口是 `--set servers[0].port=80`。用户不仅更难理解，而且以后更改`servers`顺序之后更易出错。

```yaml
#这样更易于使用
servers:
  foo:
    port: 80
  bar:
    port: 81
```

这样访问foo的port更加明显： `--set servers.foo.port=80`。

## Chart模板开发者指南

> 该指南提供 Helm Chart 模板的介绍，重点强调模板语言。

模板会生成 manifest 文件，使用 Kubernetes 可以识别的 YAML 格式描述。

### 从这里开始吧

#### 第一个模板

> 第一个创建的模板是`ConfigMap`。Kubernetes中，配置映射只是用于存储配置数据的对象。其他组件，比如pod，可以访问配置映射中的数据。

```bash
helm create mychart

rm -rf mychart/templates/*

#配置模板文件
vim mychart/templates/configmap.yaml
```

```yaml
#mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychart-configmap
data:
  myvalue: "Hello World"
```

有了这个简单的模板，现在有一个可安装的chart了。现在安装如下：

```bash
helm install full-coral ./mychart

#查看生成的 manifest
helm get manifest full-coral
```

```yaml
---
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mychart-configmap
data:
  myvalue: "Hello World"
```

#### 添加一个简单的模板调用

> 将`name:`硬编码到一个资源中不是很好的方式。名称应该是唯一的。因此我们可能希望通过插入发布名称来生成名称字段。

修改 `mychart/templates/configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
```

> `Release`前面的点表示从作用域最顶层的命名空间开始（稍后会谈作用域）。这样`.Release.Name`就可解读为“通顶层命名空间开始查找 Release对象，然后在其中找Name对象”。

> 当你想测试模板渲染但又不想安装任何内容时，可以使用`helm install --debug --dry-run goodly-guppy ./mychart`。这样会渲染模板，但是安装到chart， 会返回一个渲染后的模板如下：

```bash
helm install --debug --dry-run goodly-guppy ./mychart
```

```yaml
install.go:178: [debug] Original chart version: ""
install.go:199: [debug] CHART PATH: /Users/dhy/code/hangyudu/note/046/mychart

# release metadata
NAME: goodly-guppy
LAST DEPLOYED: Sun Dec 12 15:51:57 2021
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
USER-SUPPLIED VALUES:
{}

# 模板渲染的值
COMPUTED VALUES:
affinity: {}
autoscaling:
  enabled: false
  maxReplicas: 100
  minReplicas: 1
  targetCPUUtilizationPercentage: 80
fullnameOverride: ""
image:
  pullPolicy: IfNotPresent
  repository: nginx
  tag: ""
imagePullSecrets: []
ingress:
  annotations: {}
  className: ""
  enabled: false
  hosts:
  - host: chart-example.local
    paths:
    - path: /
      pathType: ImplementationSpecific
  tls: []
nameOverride: ""
nodeSelector: {}
podAnnotations: {}
podSecurityContext: {}
replicaCount: 1
resources: {}
securityContext: {}
service:
  port: 80
  type: ClusterIP
serviceAccount:
  annotations: {}
  create: true
  name: ""
tolerations: []

HOOKS:
MANIFEST:
---
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: goodly-guppy-configmap
data:
  myvalue: "Hello World"
```

### 内置对象

> 在上一部分中，我们用`{{ .Release.Name }}`在模板中插入版本名称。`Release`是你可以在模板中访问的高级对象之一。

> 我们在访问内置对象的时候，通过 `.` 当前是处于全局。例如 `.Release` 表示我们访问全局作用域下的 `Release` 对象.

- `Release`:  该对象描述了版本发布本身；
- `Values` 从 `values.yaml` 文件和用户提供的文件传进模板的。`values` 默认为空；
- `Chart` `Chart.yaml` 文件内容。
- `Files` 请查看这个 [文件访问](https://www.bookstack.cn/read/helm-3.7.1-zh/6f9f2ef79eeae236.md) 部分了解更多信息
- `Capabilities` 提供关于Kubernetes集群支持功能的信息
  - `Capabilities.APIVersions` 是一个版本集合
  - `Capabilities.HelmVersion.GoVersion` 是使用的Go编译器版本
- `Template` 包含了已经被执行的当前模板信息
  - `Template.Name`: 当前模板的命名空间文件路径 (e.g. `mychart/templates/mytemplate.yaml`)
  - `Template.BasePath`: 当前chart模板目录的路径 (e.g. `mychart/templates`)

### Values 文件

> 默认使用`values.yaml`，可以被父chart的`values.yaml`覆盖，继而被用户提供values文件覆盖， 最后会被`--set`参数覆盖。

values文件是普通的YAML文件。现在编辑`mychart/values.yaml`然后编辑配置映射ConfigMap模板。

```yaml
livenessProbe:
  httpGet:
    path: /user/login
    port: http
  initialDelaySeconds: 120
```

> 在发布时使用 `--set livenessProbe.exec.command=[cat,docroot/CHANGELOG.txt]` 会被修改成

```yaml
livenessProbe:
  httpGet:
    path: /user/login
    port: http
  exec:
    command:
    - cat
    - docroot/CHANGELOG.txt
  initialDelaySeconds: 120
```

>然而Kubernetes会失败，因为不能声明多个活动探针句柄。为了解决这个问题，可以指定Helm通过设定null来删除`livenessProbe.httpGet`：

```bash
helm install stable/drupal --set image=my-registry/drupal:0.1.0 --set livenessProbe.exec.command=[cat,docroot/CHANGELOG.txt] --set livenessProbe.httpGet=null
```

### 模板函数和流水线

> 到目前为止，我们已经知道了如何将信息放入模板中。 但是这些信息未被修改就放入了模板中。 有时我们希望以一种更有用的方式来转换所提供的数据。

```yaml
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  # 对字符串增加引号
  drink: {{ quote .Values.favorite.drink }}
  food: {{ quote .Values.favorite.food }}
  foodWithoutQuote: {{ .Values.favorite.food }}
```

```yaml
# values.yaml
# Default values for mychart.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.
favoriteDrink: coffee
favorite:
  drink: coffee
  food: cake
```

```bash
helm install --debug --dry-run goodly-guppy ./mychart > install.debug

vim install.debug
```

```yaml
NAME: goodly-guppy
LAST DEPLOYED: Wed Dec 15 14:59:54 2021
NAMESPACE: default
STATUS: pending-install
REVISION: 1
TEST SUITE: None
USER-SUPPLIED VALUES:
{}

COMPUTED VALUES:
favorite:
  drink: coffee
  food: cake
favoriteDrink: coffee

HOOKS:
MANIFEST:
---
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: goodly-guppy-configmap
data:
  myvalue: "Hello World"
  # 对字符串增加引号
  drink: "coffee"
  food: "cake"
  foodWithoutQuote: cake
```

#### 模板函数

```go
// 通过管道增加引号
{{ .Values.favorite.food | quote }}

// 通过管道转为大写后加引号
{{ .Values.favorite.food | upper | quote }}

// 字符重复五遍
{{ .Values.favorite.drink | repeat 5 | quote }}

// 当值为空时设置为 "tea"
{{ .Values.favorite.drink | default "tea" | quote }}

```

> 在实际的chart中，所有的静态默认值应该设置在 `values.yaml` 文件中，且不应该重复使用 `default` 命令 (否则会出现冗余)。然而这个`default` 命令很适合计算值，其不能声明在`values.yaml`文件中，比如：

```go
drink: {{ .Values.favorite.drink | default (printf "%s-tea" (include "fullname" .)) }}
```

#### 使用`lookup`函数

> `lookup` 函数可以用于在运行的集群中 *查找* 资源。lookup函数简述为`lookup apiVersion, kind, namespace, name -> 资源或者资源列表`。
>
> `name` 和 `namespace` 都是可选的，且可以作为空字符串(`""`)传递。

| 命令                                   | Lookup 函数                                |
| :------------------------------------- | :----------------------------------------- |
| `kubectl get pod mypod -n mynamespace` | `lookup “v1” “Pod” “mynamespace” “mypod”`  |
| `kubectl get pods -n mynamespace`      | `lookup “v1” “Pod” “mynamespace” “”`       |
| `kubectl get pods —all-namespaces`     | `lookup “v1” “Pod” “” “”`                  |
| `kubectl get namespace mynamespace`    | `lookup “v1” “Namespace” “” “mynamespace”` |
| `kubectl get namespaces`               | `lookup “v1” “Namespace” “” “”`            |

```go
{{ range $index, $service := (lookup "v1" "Service" "mynamespace" "").items }}
    {{/* do something with each service */}}
{{ end }}
```

> 请记住，Helm在`helm template`或者`helm install|update|delete|rollback --dry-run`时， 不应该请求请求Kubernetes API服务。由此，`lookup`函数在该案例中会返回空列表（即字典）。

#### 运算符都是函数

> 对于模板来说，运算符(`eq`, `ne`, `lt`, `gt`, `and`, `or`等等) 都是作为函数来实现的。 在管道符中，操作可以按照圆括号分组。

### 模板函数列表

[helm function_list](https://helm.sh/docs/chart_template_guide/function_list/)

### 流控制

- `if`/`else`， 用来创建条件语句
- `with`， 用来指定范围
- `range`， 提供”for each”类型的循环
- `define` 在模板中声明一个新的命名模板
- `template` 导入一个命名模板
- `block` 声明一种特殊的可填充的模板块

#### If/Else

```go
{{ if eq .Values.favorite.drink "coffee" }}mug: "true"{{ end }}
```

#### 控制空格

> `{{-` (包括添加的横杠和空格)表示向左删除空白， 而 `-}}`表示右边的空格应该被去掉。 *一定注意空格就是换行*

```go
  {{- if eq .Values.favorite.drink "coffee" }}
  mug: "true"
  {{- end }}
```

#### 修改使用`with`的范围

> 下一个控制结构是`with`操作。这个用来控制变量范围。回想一下，`.`是对 *当前作用域* 的引用。因此 `.Values`就是告诉模板在当前作用域查找`Values`对象。
>
> 作用域可以被改变。`with`允许你为特定对象设定当前作用域(`.`)。比如，我们已经在使用`.Values.favorite`。 修改配置映射中的`.`的作用域指向`.Values.favorite`：

```yaml
  {{- with .Values.favorite }}
  drink: {{ .drink | default "tea" | quote }}
  food: {{ .food | upper | quote }}
  release: {{ .Release.Name }}
  {{- end }}
```

#### 使用`range`操作循环

```yaml
# values.yaml
favorite:
  drink: coffee
  food: pizza
pizzaToppings:
  - mushrooms
  - cheese
  - peppers
  - onions
```

>现在我们有了一个`pizzaToppings`列表（模板中称为切片）。修改模板把这个列表打印到配置映射中：
>
>或者，我们可以使用`$`从父作用域中访问`Release.Name`对象。**当模板开始执行后`$`会被映射到根作用域**，且执行过程中不会更改。 下面这种方式也可以正常工作：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  {{- with .Values.favorite }}
  drink: {{ .drink | default "tea" | quote }}
  food: {{ .food | upper | quote }}
  {{- end }}
  toppings: |-
    {{- range .Values.pizzaToppings }}
    - {{ . | title | quote }}
    {{- end }}
```

### 变量

```go
// 为变量赋值，通过 $ 将变量映射到根作用域
{{- $relname := .Release.Name -}}

// 引用变量
release: {{ $relname }}
```

### 命名模板

> *命名模板* (有时称作一个 *部分* 或一个 *子模板*)仅仅是在文件内部定义的模板，并使用了一个名字。有两种创建方式和几种不同的使用方法。

> 三种声明和管理模板的方法：`define`，`template`，和`block`。

> 命名模板时要记住一个重要细节：**模板名称是全局的**。

#### 局部的和`_`文件

> 命名以下划线(`_`)开始的文件则假定 *没有* 包含清单内容。这些文件不会渲染为Kubernetes对象定义，但在其他chart模板中都可用。

#### 用`define`和`template`声明和使用模板

```yaml
{{ define "MY.NAME" }}
  # body of template here
{{ end }}
```

```yaml
{{- define "mychart.labels" }}
  labels:
    generator: helm
    date: {{ now | htmlDate }}
{{- end }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  {{- template "mychart.labels" }}
data:
  myvalue: "Hello World"
  {{- range $key, $val := .Values.favorite }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
```

#### 设置模板范围

> 下面的模板会渲染异常

```yaml
{{/* Generate basic labels */}}
{{- define "mychart.labels" }}
  labels:
    generator: helm
    date: {{ now | htmlDate }}
    chart: {{ .Chart.Name }}
    version: {{ .Chart.Version }}
{{- end }}
```

> 我们通过 `--disable-openapi-validation` 发现 chart 和 version 字段没有正常渲染。

```yaml
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: moldy-jaguar-configmap
  labels:
    generator: helm
    date: 2021-03-06
    chart:
    version:
```

> 这是因为当一个（使用`define`创建的）命名模板被渲染时，会接收被`template`调用传入的内容。 在我们的示例中，包含模板如下：

```yaml
{{- template "mychart.labels" }}
```

>没有内容传入，所以模板中无法用`.`访问任何内容。但这个很容易解决，只需要传递一个范围给模板：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  {{- template "mychart.labels" . }}
```

#### `include`方法

```yaml
{{- define "mychart.app" -}}
app_name: {{ .Chart.Name }}
app_version: "{{ .Chart.Version }}"
{{- end -}}
```

>现在假设我想把这个插入到模板的`labels:`部分和`data:`部分：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  labels:
    {{ template "mychart.app" . }}
data:
  myvalue: "Hello World"
  {{- range $key, $val := .Values.favorite }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
{{ template "mychart.app" . }}
```

> 再次通过 `--disable-openapi-validation` 查看渲染结果

```yaml
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: measly-whippet-configmap
  labels:
    app_name: mychart
app_version: "0.1.0"
data:
  myvalue: "Hello World"
  drink: "coffee"
  food: "pizza"
app_name: mychart
app_version: "0.1.0"
```

> 注意两处的`app_version`缩进都不对，为啥？因为被替换的模板中文本是左对齐的。由于`template`是一个行为，不是方法，无法将 `template`调用的输出传给其他方法，数据只是简单地按行插入。

> 为了处理这个问题，Helm提供了一个`template`的可选项，可以将模板内容导入当前管道，然后传递给管道中的其他方法。下面这个示例，使用`indent`正确地缩进了`mychart.app`模板：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
  labels:
{{ include "mychart.app" . | indent 4 }}
data:
  myvalue: "Hello World"
  {{- range $key, $val := .Values.favorite }}
  {{ $key }}: {{ $val | quote }}
  {{- end }}
{{ include "mychart.app" . | indent 2 }}
```

>现在生成的YAML每一部分都可以正确缩进了：

```yaml
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: edgy-mole-configmap
  labels:
    app_name: mychart
    app_version: "0.1.0"
data:
  myvalue: "Hello World"
  drink: "coffee"
  food: "pizza"
  app_name: mychart
  app_version: "0.1.0"
```

> **Helm模板中使用`include`而不是`template`被认为是更好的方式 只是为了更好地处理YAML文档的输出格式**

### 创建一个NOTES.txt文件

> 要在chart添加安装说明，只需创建`templates/NOTES.txt`文件即可。该文件是纯文本，但会像模板一样处理， 所有正常的模板函数和对象都是可用的。

### 在模板内部访问文件

> Helm 提供了通过`.Files`对象访问文件的方法。

#### Basic example

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  # 通过 $files 引用 .Files 对象
  {{- $files := .Files }}
  # 通过 tuple 创建可遍历的文件列表
  {{- range tuple "config1.toml" "config2.toml" "config3.toml" }}
  # 获取文件名
  {{ . }}: |-
        # 打印文件内容
        {{ $files.Get . }}
  {{- end }}
```

```yaml
# Source: mychart/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: quieting-giraf-configmap
data:
  config1.toml: |-
        message = Hello from config 1
  config2.toml: |-
        message = This is config 2
  config3.toml: |-
        message = Goodbye from config 3
```

#### Path helpers

> helm 从 go 的 path 引入了一些功能：
>
> - Base
> - Dir
> - Ext
> - IsAbs
> - Clean

#### Glob patterns

> 我们提供了一个 `Files.Glob(pattern string)`方法来使用 [全局模式](https://godoc.org/github.com/gobwas/glob)的灵活性读取特定文件。`.Glob`返回一个`Files`类型，因此你可以在返回对象上调用任意的`Files`方法。

假设我们有这样的目录结构

```yaml
foo/:
  foo.txt foo.yaml
bar/:
  bar.go bar.conf baz.yaml
```

```go
{{ $currentScope := .}}
{{ range $path, $_ :=  .Files.Glob  "**.yaml" }}
    {{- with $currentScope}}
        {{ .Files.Get $path }}
    {{- end }}
{{ end }}
```

```go
{{ range $path, $_ :=  .Files.Glob  "**.yaml" }}
      {{ $.Files.Get $path }}
{{ end }}
```

#### ConfigMap and Secrets utility functions

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: conf
data:
{{ (.Files.Glob "foo/*").AsConfig | indent 2 }}
---
apiVersion: v1
kind: Secret
metadata:
  name: very-secret
type: Opaque
data:
{{ (.Files.Glob "bar/*").AsSecrets | indent 2 }}
```

### 子chart和全局值

#### 创建子chart

```bash
cd mychart/charts
helm create mysubchart
#Creating mysubchart
rm -rf mysubchart/templates/*
```

#### 在子chart中添加值和模板

```yaml
# 修改 mysubchart/values.yaml
dessert: cake
```

```yaml
# 修改 mysubcharts/template/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-cfgmap2
data:
  dessert: {{ .Values.dessert }}
```

```bash
# 安装 Chart
helm install --generate-name --dry-run --debug ./mysubchart
```

#### 全局Chart值

> 全局值是使用完全一样的名字在所有的chart及子chart中都能访问的值。全局变量需要显示声明。不能将现有的非全局值作为全局值使用。

> 这些值数据类型有个保留部分叫`Values.global`，可以用来设置全局值。在`mychart/values.yaml`文件中设置一个值如下（注意，父 chart 本身就可以访问子 chart 的值）：

```yaml
# mychart/template/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  myvalue: "Hello World"
  # 对字符串增加引号
  drink: {{ quote .Values.favorite.drink }}
  food: {{ quote .Values.favorite.food }}
  foodWithoutQuote: {{ .Values.favorite.food }}
  dessert: {{ .Values.mysubchart.dessert }}
```

#### 与子chart共享模板

> 父chart和子chart可以共享模板。在任意chart中定义的块在其他chart中也是可用的。

### .helmignore 文件

> `.helmignore` 文件用来指定你不想包含在你的helm chart中的文件。

### 调试模板

> 以下命令有助于调试：
>
> - `helm lint` 是验证chart是否遵循最佳实践的首选工具
> - `helm install --dry-run --debug` 或 `helm template --debug`：我们已经看过这个技巧了， 这是让服务器渲染模板的好方法，然后返回生成的清单文件。
> - `helm get manifest`: 这是查看安装在服务器上的模板的好方法。

### 附录：YAML 技术

#### 特殊符号

>- `|` 用于声明多行
>- `+` 保留尾随空格
>- `-` 删除尾随空格
>- `>` 折叠

#### 类型

> 在一些场景中，可以使用YAML节点标签强制推断特定类型

```yaml
coffee: "yes, please"
# 提示 age 是字符串
age: !!str 21
# 提示 port 是 int
port: !!int "80"
```

#### YAML中的字符串

```yaml
# 声明多行字符串
# 等同于 Latte\nCappuccino\nEspresso\n
coffee: |
  Latte
  Cappuccino
  Espresso

# 如果需要YAML处理器去掉末尾的换行符，在| 后面添加-：
# 等同于 Latte\nCappuccino\nEspresso
coffee: |-
  Latte
  Cappuccino
  Espresso

# 保留尾随空格。可以使用 |+符号：
# 等同于  Latte\nCappuccino\nEspresso\n\n\n
coffee: |+
  Latte
  Cappuccino
  Espresso  


another: value
```

#### 折叠多行字符串

```yaml
#Latte Cappuccino Espresso\n
#注意，除了最后一个空格之外，所有的换行符都转换成了空格
coffee: >
  Latte
  Cappuccino
  Espresso
#组合空格控制符和折叠字符标记 >- 来替换或取消所有的新行。
#Latte\n 12 oz\n 16 oz\nCappuccino Espresso
coffee: >-
  Latte
    12 oz
    16 oz
  Cappuccino
  Espresso
```

#### YAML 锚点

```yaml
coffee: "yes, please"
favorite: &favoriteCoffee "Cappucino"
coffees:
  - Latte
  - *favoriteCoffee
  - Espresso
```

>上面示例中，&favoriteCoffee 设置成了Cappuccino的引用。之后，通过*favoriteCoffee使用引用。 这样coffees 就变成了 Latte, Cappuccino, Espresso。

锚点在一些场景中很有用，但另一方面，锚点可能会引起细微的错误：第一次使用YAML时，将展开引用，然后将其丢弃。

因此，如果我们解码再重新编码上述示例，产生的YAML就会时这样：

```yaml
coffee: yes, please
favorite: Cappucino
coffees:
- Latte
- Cappucino
- Espresso
```






























