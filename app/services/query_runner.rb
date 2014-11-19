class QueryRunner
  # Run a query for the data explorer interface.
  # Arguments:
  #   sql: a SQL select statement
  #   params: any provided query parameters
  #   opts: Options.
  #     explain: Include an EXPLAIN in the result.
  #
  # Returns: Hash
  #   :error - text of any SQL error. If present, this and :error_type are the only things returned
  #   :error_type - Ruby class name of the error
  #   :columns - array of the names of the returned columns
  #   :explain - array of strings for the analysis result
  #   :result - array of the result rows, which are Hashes from the column name to the value
  def self.run_explorer_query(select_sql, params, opts)
    explain_result = nil

    # Prevent data-modifying WITH statements by nesting it
    # TODO is that actually right
    sql = <<SQL
SELECT * FROM (
  WITH results AS (

#{select_sql}

  )
  SELECT * FROM results
) x
SQL

    begin
      sql_result = SqlBuilder.new(sql).exec(params)
      if opts[:explain]
        # Make sure that they can't prefix with ANALYZE to execute a data-modifying WITH
        explain_result = SqlBuilder.new("EXPLAIN SELECT * FROM ( \n#{select_sql}\n ) x").exec(params)
      end
    rescue ActiveRecord::ActiveRecordError => ex
      return { error: ex.message, error_type: ex.class.to_s }
    end

    retval = {}
    retval[:columns] = sql_result.first.map(&:first)
    if explain_result
      retval[:explain] = explain_result.map { |row| row["QUERY PLAN"] }
    end
    retval[:result] = sql_result

    retval
  end
end