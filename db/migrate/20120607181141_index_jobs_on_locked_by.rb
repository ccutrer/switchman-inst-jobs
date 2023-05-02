# frozen_string_literal: true

class IndexJobsOnLockedBy < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def up
    add_index :delayed_jobs, :locked_by, algorithm: :concurrently, where: "locked_by IS NOT NULL"
  end

  def down
    remove_index :delayed_jobs, :locked_by
  end
end
