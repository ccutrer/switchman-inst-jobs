class DropFailedJobsOriginalId < ActiveRecord::Migration[4.2]
  def connection
    Delayed::Backend::ActiveRecord::AbstractJob.connection
  end

  def up
    remove_column :failed_jobs, :original_id
  end

  def down
    add_column :failed_jobs, :original_id, :integer, limit: 8
  end
end
