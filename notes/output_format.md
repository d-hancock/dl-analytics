Section | Field | Description
Table | schema, table_name | Identifies each table.
Columns | key | Primary Key ("PK") or null.
 | name | Column name.
 | data_type | SQL data type.
 | max_length_bytes | Max length (for types like VARCHAR) or null.
 | allow_nulls | Boolean.
 | identity | Boolean (true if auto-increment).
 | default | Default value or null.
Indexes | key | ("PK", "UK", or null).
 | name | Index name.
 | key_columns | List of indexed columns.
 | included_columns | List of included columns (if any).
 | unique | Boolean.
 | page_locks | Boolean.
 | fill_factor | Integer percentage (or null).
Foreign Keys | name | FK constraint name.
 | column_name | FK column on this table.
 | references_schema | Referenced schema.
 | references_table | Referenced table.
 | references_column | Referenced column.
Computed Columns | name | Computed column name.
 | column_definition | SQL Expression used to compute it.