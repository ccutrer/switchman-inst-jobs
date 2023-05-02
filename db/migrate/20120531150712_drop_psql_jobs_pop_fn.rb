# frozen_string_literal: true

class DropPsqlJobsPopFn < ActiveRecord::Migration[4.2]
  def up
    if connection.adapter_name == "PostgreSQL"
      connection.execute("DROP FUNCTION IF EXISTS pop_from_delayed_jobs(varchar, varchar, integer, integer, timestamp without time zone)")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
