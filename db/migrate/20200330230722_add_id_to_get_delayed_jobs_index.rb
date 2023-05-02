# frozen_string_literal: true

class AddIdToGetDelayedJobsIndex < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    rename_index :delayed_jobs, "get_delayed_jobs_index", "get_delayed_jobs_index_old"
    add_index :delayed_jobs,
              %i[queue priority run_at id],
              algorithm: :concurrently,
              where: "locked_at IS NULL AND next_in_strand",
              name: "get_delayed_jobs_index"
    remove_index :delayed_jobs, name: "get_delayed_jobs_index_old"
  end

  def down
    rename_index :delayed_jobs, "get_delayed_jobs_index", "get_delayed_jobs_index_old"
    add_index :delayed_jobs,
              %i[priority run_at queue],
              algorithm: :concurrently,
              where: "locked_at IS NULL AND next_in_strand",
              name: "get_delayed_jobs_index"
    remove_index :delayed_jobs, name: "get_delayed_jobs_index_old"
  end
end
