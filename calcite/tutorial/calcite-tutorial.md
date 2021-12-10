# calcite tutorial

## reference

[calcite tutorial](https://calcite.apache.org/docs/tutorial.html)

## tutorial

> It uses a simple adapter that makes a directory of CSV files appear to be a schema containing tables. Calcite does the rest, and provides a full SQL interface.
>
> Even though there are not many lines of code, it covers several important concepts:

- user-defined schema using SchemaFactory and Schema interfaces;
- declaring schemas in a model JSON file;
- declaring views in a model JSON file;
- user-defined table using the Table interface;
- determining the record type of a table;
- a simple implementation of Table, using the ScannableTable interface, that enumerates all rows directly;
- a more advanced implementation that implements FilterableTable, and can filter out rows according to simple predicates;
- advanced implementation of Table, using TranslatableTable, that translates to relational operators using planner rules.

## download

```bash
git clone https://github.com/apache/calcite.git
cd calcite/example/csv
./sqlline
```

## First queries

```bash
./sqlline
```

```sql
!connect jdbc:calcite:model=src/test/resources/model.json admin admin
```

```sql
!tables
```

```
+-----------+-------------+------------+--------------+---------+----------+------------+-----------+---------------------------+----------------+
| TABLE_CAT | TABLE_SCHEM | TABLE_NAME |  TABLE_TYPE  | REMARKS | TYPE_CAT | TYPE_SCHEM | TYPE_NAME | SELF_REFERENCING_COL_NAME | REF_GENERATION |
+-----------+-------------+------------+--------------+---------+----------+------------+-----------+---------------------------+----------------+
|           | SALES       | DEPTS      | TABLE        |         |          |            |           |                           |                |
|           | SALES       | EMPS       | TABLE        |         |          |            |           |                           |                |
|           | SALES       | SDEPTS     | TABLE        |         |          |            |           |                           |                |
|           | metadata    | COLUMNS    | SYSTEM TABLE |         |          |            |           |                           |                |
|           | metadata    | TABLES     | SYSTEM TABLE |         |          |            |           |                           |                |
+-----------+-------------+------------+--------------+---------+----------+------------+-----------+---------------------------+----------------+
```

```sql
select * from emps;
```

```
+-------+-------+--------+--------+---------------+-------+------+---------+---------+------------+
| EMPNO | NAME  | DEPTNO | GENDER |     CITY      | EMPID | AGE  | SLACKER | MANAGER |  JOINEDAT  |
+-------+-------+--------+--------+---------------+-------+------+---------+---------+------------+
| 100   | Fred  | 10     |        |               | 30    | 25   | true    | false   | 1996-08-03 |
| 110   | Eric  | 20     | M      | San Francisco | 3     | 80   |         | false   | 2001-01-01 |
| 110   | John  | 40     | M      | Vancouver     | 2     | null | false   | true    | 2002-05-03 |
| 120   | Wilma | 20     | F      |               | 1     | 5    |         | true    | 2005-09-07 |
| 130   | Alice | 40     | F      | Vancouver     | 2     | null | false   | true    | 2007-01-01 |
+-------+-------+--------+--------+---------------+-------+------+---------+---------+------------+
```

## Schema discovery

> Now, how did Calcite find these tables? Remember, core Calcite does not know anything about CSV files. (As a **“database without a storage layer”**, Calcite doesn’t know about any file formats.) Calcite knows about those tables because we told it to run code in the calcite-example-csv project.

1. we define a schema based on a schema factory class in a model file.
2. the schema factory creates a schema, and the schema creates several tables, each of which knows how to get data by scanning a CSV file.
3. after Calcite has parsed the query and planned it to use those tables, Calcite invokes the tables to read the data as the query is being executed. Now let’s look at those steps in more detail.

Here is the model:

```json
{
  version: '1.0',
  defaultSchema: 'SALES',
  schemas: [
    {
      name: 'SALES',
      type: 'custom',
      factory: 'org.apache.calcite.adapter.csv.CsvSchemaFactory',
      operand: {
        directory: 'sales'
      }
    }
  ]
}
```

### CsvSchemaFactory

```java
/**
 * Factory that creates a {@link CsvSchema}.
 *
 * <p>Allows a custom schema to be included in a <code><i>model</i>.json</code>
 * file.
 */
@SuppressWarnings("UnusedDeclaration")
public class CsvSchemaFactory implements SchemaFactory {
  /** Public singleton, per factory contract. */
  public static final CsvSchemaFactory INSTANCE = new CsvSchemaFactory();

  private CsvSchemaFactory() {
  }

  @Override public Schema create(SchemaPlus parentSchema, String name,
      Map<String, Object> operand) {
    final String directory = (String) operand.get("directory");
    final File base =
        (File) operand.get(ModelHandler.ExtraOperand.BASE_DIRECTORY.camelName);
    File directoryFile = new File(directory);
    if (base != null && !directoryFile.isAbsolute()) {
      directoryFile = new File(base, directory);
    }
    String flavorName = (String) operand.get("flavor");
    CsvTable.Flavor flavor;
    if (flavorName == null) {
      flavor = CsvTable.Flavor.SCANNABLE;
    } else {
      flavor = CsvTable.Flavor.valueOf(flavorName.toUpperCase(Locale.ROOT));
    }
    return new CsvSchema(directoryFile, flavor);
  }
}
```

### CsvTest

```java
  @Test void testPrepared() throws SQLException {
    final Properties properties = new Properties();
    properties.setProperty("caseSensitive", "true");
    try (Connection connection =
        DriverManager.getConnection("jdbc:calcite:", properties)) {
      final CalciteConnection calciteConnection = connection.unwrap(
          CalciteConnection.class);

      final Schema schema =
          CsvSchemaFactory.INSTANCE
              .create(calciteConnection.getRootSchema(), null,
                  ImmutableMap.of("directory",
                      resourcePath("sales"), "flavor", "scannable"));
      calciteConnection.getRootSchema().add("TEST", schema);
      final String sql = "select * from \"TEST\".\"DEPTS\" where \"NAME\" = ?";
      final PreparedStatement statement2 =
          calciteConnection.prepareStatement(sql);

      statement2.setString(1, "Sales");
      final ResultSet resultSet1 = statement2.executeQuery();
      Consumer<ResultSet> expect = expect("DEPTNO=10; NAME=Sales");
      expect.accept(resultSet1);
    }
  }
```

### Schema

> Driven by the model, the schema factory instantiates a single schema called ‘SALES’. The schema is an instance of [org.apache.calcite.adapter.csv.CsvSchema](https://github.com/apache/calcite/blob/master/example/csv/src/main/java/org/apache/calcite/adapter/csv/CsvSchema.java) and implements the Calcite interface [Schema](https://calcite.apache.org/javadocAggregate/org/apache/calcite/schema/Schema.html).

```java
/**
 * A namespace for tables and functions.
 *
 * <p>A schema can also contain sub-schemas, to any level of nesting. Most
 * providers have a limited number of levels; for example, most JDBC databases
 * have either one level ("schemas") or two levels ("database" and
 * "catalog").</p>
 *
 * <p>There may be multiple overloaded functions with the same name but
 * different numbers or types of parameters.
 * For this reason, {@link #getFunctions} returns a list of all
 * members with the same name. Calcite will call
 * {@link Schemas#resolve(org.apache.calcite.rel.type.RelDataTypeFactory, String, java.util.Collection, java.util.List)}
 * to choose the appropriate one.</p>
 *
 * <p>The most common and important type of member is the one with no
 * arguments and a result type that is a collection of records. This is called a
 * <dfn>relation</dfn>. It is equivalent to a table in a relational
 * database.</p>
 *
 * <p>For example, the query</p>
 *
 * <blockquote>select * from sales.emps</blockquote>
 *
 * <p>is valid if "sales" is a registered
 * schema and "emps" is a member with zero parameters and a result type
 * of <code>Collection(Record(int: "empno", String: "name"))</code>.</p>
 *
 * <p>A schema may be nested within another schema; see
 * {@link Schema#getSubSchema(String)}.</p>
 */
public interface Schema {
  /**
   * Returns a table with a given name, or null if not found.
   *
   * @param name Table name
   * @return Table, or null
   */
  @Nullable Table getTable(String name);

  /**
   * Returns the names of the tables in this schema.
   *
   * @return Names of the tables in this schema
   */
  Set<String> getTableNames();

  /**
   * Returns a type with a given name, or null if not found.
   *
   * @param name Table name
   * @return Table, or null
   */
  @Nullable RelProtoDataType getType(String name);

  /**
   * Returns the names of the types in this schema.
   *
   * @return Names of the tables in this schema
   */
  Set<String> getTypeNames();

  /**
   * Returns a list of functions in this schema with the given name, or
   * an empty list if there is no such function.
   *
   * @param name Name of function
   * @return List of functions with given name, or empty list
   */
  Collection<Function> getFunctions(String name);

  /**
   * Returns the names of the functions in this schema.
   *
   * @return Names of the functions in this schema
   */
  Set<String> getFunctionNames();

  /**
   * Returns a sub-schema with a given name, or null.
   *
   * @param name Sub-schema name
   * @return Sub-schema with a given name, or null
   */
  @Nullable Schema getSubSchema(String name);

  /**
   * Returns the names of this schema's child schemas.
   *
   * @return Names of this schema's child schemas
   */
  Set<String> getSubSchemaNames();

  /**
   * Returns the expression by which this schema can be referenced in generated
   * code.
   *
   * @param parentSchema Parent schema
   * @param name Name of this schema
   * @return Expression by which this schema can be referenced in generated code
   */
  Expression getExpression(@Nullable SchemaPlus parentSchema, String name);

  /** Returns whether the user is allowed to create new tables, functions
   * and sub-schemas in this schema, in addition to those returned automatically
   * by methods such as {@link #getTable(String)}.
   *
   * <p>Even if this method returns true, the maps are not modified. Calcite
   * stores the defined objects in a wrapper object.
   *
   * @return Whether the user is allowed to create new tables, functions
   *   and sub-schemas in this schema
   */
  boolean isMutable();

  /** Returns the snapshot of this schema as of the specified time. The
   * contents of the schema snapshot should not change over time.
   *
   * @param version The current schema version
   *
   * @return the schema snapshot.
   */
  Schema snapshot(SchemaVersion version);

  /** Table type. */
  enum TableType {}
}
```

> **A schema’s job is to produce a list of tables. **

### CsvSchema

```java
public class CsvSchema extends AbstractSchema {
  private final File directoryFile;
  private final CsvTable.Flavor flavor;
  private Map<String, Table> tableMap;

  /**
   * Creates a CSV schema.
   *
   * @param directoryFile Directory that holds {@code .csv} files
   * @param flavor     Whether to instantiate flavor tables that undergo
   *                   query optimization
   */
  public CsvSchema(File directoryFile, CsvTable.Flavor flavor) {
    super();
    this.directoryFile = directoryFile;
    this.flavor = flavor;
  }

  /** Looks for a suffix on a string and returns
   * either the string with the suffix removed
   * or the original string. */
  private static String trim(String s, String suffix) {
    String trimmed = trimOrNull(s, suffix);
    return trimmed != null ? trimmed : s;
  }

  /** Looks for a suffix on a string and returns
   * either the string with the suffix removed
   * or null. */
  private static String trimOrNull(String s, String suffix) {
    return s.endsWith(suffix)
        ? s.substring(0, s.length() - suffix.length())
        : null;
  }

  @Override protected Map<String, Table> getTableMap() {
    if (tableMap == null) {
      tableMap = createTableMap();
    }
    return tableMap;
  }

  private Map<String, Table> createTableMap() {
    // Look for files in the directory ending in ".csv", ".csv.gz", ".json",
    // ".json.gz".
    final Source baseSource = Sources.of(directoryFile);
    File[] files = directoryFile.listFiles((dir, name) -> {
      final String nameSansGz = trim(name, ".gz");
      return nameSansGz.endsWith(".csv")
          || nameSansGz.endsWith(".json");
    });
    if (files == null) {
      System.out.println("directory " + directoryFile + " not found");
      files = new File[0];
    }
    // Build a map from table name to table; each file becomes a table.
    final ImmutableMap.Builder<String, Table> builder = ImmutableMap.builder();
    for (File file : files) {
      // source 是我们表的实际内容
      Source source = Sources.of(file);
      // sourceSansGz 是我们的表名
      Source sourceSansGz = source.trim(".gz");
      // 将以 json 作为后缀的文件作为输入源
      final Source sourceSansJson = sourceSansGz.trimOrNull(".json");
      if (sourceSansJson != null) {
        final Table table = new JsonScannableTable(source);
        builder.put(sourceSansJson.relative(baseSource).path(), table);
      }
      // 将以 csv 作为后缀的文件作为输入源
      final Source sourceSansCsv = sourceSansGz.trimOrNull(".csv");
      if (sourceSansCsv != null) {
        final Table table = createTable(source);
        builder.put(sourceSansCsv.relative(baseSource).path(), table);
      }
    }
    return builder.build();
  }

  /** Creates different sub-type of table based on the "flavor" attribute. */
  private Table createTable(Source source) {
    switch (flavor) {
    case TRANSLATABLE:
      return new CsvTranslatableTable(source, null);
    case SCANNABLE:
      return new CsvScannableTable(source, null);
    case FILTERABLE:
      return new CsvFilterableTable(source, null);
    default:
      throw new AssertionError("Unknown flavor " + this.flavor);
    }
  }
}
```

## Tables and views in schemas

### model-with-view.json

> The line `type: 'view'` tags `FEMALE_EMPS` as a view, as opposed to a regular table or a custom table. 

```json
{
  "version": "1.0",
  "defaultSchema": "SALES",
  "schemas": [
    {
      "name": "SALES",
      "type": "custom",
      "factory": "org.apache.calcite.adapter.csv.CsvSchemaFactory",
      "operand": {
        "directory": "sales"
      },
      "tables": [
        {
          "name": "FEMALE_EMPS",
          "type": "view",
          "sql": "SELECT * FROM emps WHERE gender = 'F'"
        }
      ]
    }
  ]
}
```

> JSON doesn’t make it easy to author long strings, so Calcite supports an alternative syntax. If your view has a long SQL statement, you can instead supply a list of lines rather than a single string:

```json
{
  name: 'FEMALE_EMPS',
  type: 'view',
  sql: [
    'SELECT * FROM emps',
    'WHERE gender = \'F\''
  ]
}
```

### Custom tables

> Custom tables are tables whose implementation is driven by user-defined code. They don’t need to live in a custom schema.

### model-with-custom-table.json

```json
{
  "version": "1.0",
  "defaultSchema": "CUSTOM_TABLE",
  "schemas": [
    {
      "name": "CUSTOM_TABLE",
      "tables": [
        {
          "name": "EMPS",
          "type": "custom",
          "factory": "org.apache.calcite.adapter.csv.CsvTableFactory",
          "operand": {
            "file": "sales/EMPS.csv.gz",
            "flavor": "scannable"
          }
        }
      ]
    }
  ]
}
```

```sql
!connect jdbc:calcite:model=src/test/resources/model-with-custom-table.json admin admin
```

### CsvTableFactory

```java
/**
 * Factory that creates a {@link CsvTranslatableTable}.
 *
 * <p>Allows a file-based table to be included in a model.json file, even in a
 * schema that is not based upon {@link FileSchema}.
 */
@SuppressWarnings("UnusedDeclaration")
public class CsvTableFactory implements TableFactory<CsvTable> {
  // public constructor, per factory contract
  public CsvTableFactory() {
  }

  @Override public CsvTable create(SchemaPlus schema, String name,
      Map<String, Object> operand, @Nullable RelDataType rowType) {
    String fileName = (String) operand.get("file");
    final File base =
        (File) operand.get(ModelHandler.ExtraOperand.BASE_DIRECTORY.camelName);
    final Source source = Sources.file(base, fileName);
    final RelProtoDataType protoRowType =
        rowType != null ? RelDataTypeImpl.proto(rowType) : null;
    return new CsvTranslatableTable(source, protoRowType);
  }
}
```

## Optimizing queries using planner rules

> Calcite supports query optimization by adding *planner rules*. Planner rules operate by looking for patterns in the query parse tree (for instance a project on top of a certain kind of table), and replacing the matched nodes in the tree by a new set of nodes which implement the optimization.

### CsvTranslatableTable

> `CsvTranslatableTable` implements the `TranslatableTable.toRel()` method to create [CsvTableScan](https://github.com/apache/calcite/blob/master/example/csv/src/main/java/org/apache/calcite/adapter/csv/CsvTableScan.java). Table scans are the leaves of a query operator tree. The usual implementation is `EnumerableTableScan`, but we have created a distinctive sub-type that will cause rules to fire.

```java
/**
 * Table based on a CSV file.
 *
 * <p>Copied from {@code CsvTranslatableTable} in demo CSV adapter,
 * with more advanced features.
 */
public class CsvTranslatableTable extends CsvTable
    implements QueryableTable, TranslatableTable {
  /** Creates a CsvTable. */
  CsvTranslatableTable(Source source, RelProtoDataType protoRowType) {
    super(source, protoRowType);
  }

  @Override public String toString() {
    return "CsvTranslatableTable";
  }

  /** Returns an enumerable over a given projection of the fields. */
  @SuppressWarnings("unused") // called from generated code
  public Enumerable<Object> project(final DataContext root,
      final int[] fields) {
    final AtomicBoolean cancelFlag = DataContext.Variable.CANCEL_FLAG.get(root);
    return new AbstractEnumerable<Object>() {
      @Override public Enumerator<Object> enumerator() {
        JavaTypeFactory typeFactory = root.getTypeFactory();
        return new CsvEnumerator<>(source, cancelFlag,
            getFieldTypes(typeFactory), ImmutableIntList.of(fields));
      }
    };
  }

  @Override public Expression getExpression(SchemaPlus schema, String tableName,
      Class clazz) {
    return Schemas.tableExpression(schema, getElementType(), tableName, clazz);
  }

  @Override public Type getElementType() {
    return Object[].class;
  }

  @Override public <T> Queryable<T> asQueryable(QueryProvider queryProvider,
      SchemaPlus schema, String tableName) {
    throw new UnsupportedOperationException();
  }

  @Override public RelNode toRel(
      RelOptTable.ToRelContext context,
      RelOptTable relOptTable) {
    // Request all fields.
    final int fieldCount = relOptTable.getRowType().getFieldCount();
    final int[] fields = CsvEnumerator.identityList(fieldCount);
    return new CsvTableScan(context.getCluster(), relOptTable, this, fields);
  }
}
```

























