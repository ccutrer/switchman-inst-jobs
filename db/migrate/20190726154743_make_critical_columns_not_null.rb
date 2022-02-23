class MakeCriticalColumnsNotNull < ActiveRecord::Migration[4.2]
  def up
    change_column_null :delayed_jobs, :run_at, false
    change_column_null :delayed_jobs, :queue, false
  end

  def down
    change_column_null :delayed_jobs, :run_at, true
    change_column_null :delayed_jobs, :queue, true
  end
end
