class AddDelayedJobsNextInStrand < ActiveRecord::Migration[4.2]
  def up
    remove_index :delayed_jobs, name: 'index_delayed_jobs_for_get_next'

    add_column :delayed_jobs, :next_in_strand, :boolean, default: true, null: false

    # create the new index
    connection.execute("CREATE INDEX get_delayed_jobs_index ON #{connection.quote_table_name(::Delayed::Job.table_name)} (priority, run_at, queue) WHERE locked_at IS NULL AND next_in_strand = 't'")

    # create the insert trigger
    execute(<<-CODE)
    CREATE FUNCTION #{connection.quote_table_name('delayed_jobs_before_insert_row_tr_fn')} () RETURNS trigger AS $$
    BEGIN
      LOCK delayed_jobs IN SHARE ROW EXCLUSIVE MODE;
      IF (SELECT 1 FROM delayed_jobs WHERE strand = NEW.strand LIMIT 1) = 1 THEN
        NEW.next_in_strand := 'f';
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql SET search_path TO #{::Switchman::Shard.current.name};
    CODE
    execute("CREATE TRIGGER delayed_jobs_before_insert_row_tr BEFORE INSERT ON #{connection.quote_table_name(::Delayed::Job.table_name)} FOR EACH ROW WHEN (NEW.strand IS NOT NULL) EXECUTE PROCEDURE #{connection.quote_table_name('delayed_jobs_before_insert_row_tr_fn')}()")

    # create the delete trigger
    execute(<<-CODE)
    CREATE FUNCTION #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')} () RETURNS trigger AS $$
    BEGIN
      UPDATE delayed_jobs SET next_in_strand = 't' WHERE id = (SELECT id FROM delayed_jobs j2 WHERE j2.strand = OLD.strand ORDER BY j2.strand, j2.id ASC LIMIT 1);
      RETURN OLD;
    END;
    $$ LANGUAGE plpgsql SET search_path TO #{::Switchman::Shard.current.name};
    CODE
    execute("CREATE TRIGGER delayed_jobs_after_delete_row_tr AFTER DELETE ON #{connection.quote_table_name(::Delayed::Job.table_name)} FOR EACH ROW WHEN (OLD.strand IS NOT NULL AND OLD.next_in_strand = 't') EXECUTE PROCEDURE #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')} ()")

    execute(%{UPDATE #{connection.quote_table_name(::Delayed::Job.table_name)} SET next_in_strand = 'f' WHERE strand IS NOT NULL AND id <> (SELECT id FROM #{connection.quote_table_name(::Delayed::Job.table_name)} j2 WHERE j2.strand = delayed_jobs.strand ORDER BY j2.strand, j2.id ASC LIMIT 1)})
  end

  def down
    execute %(DROP TRIGGER delayed_jobs_before_insert_row_tr ON #{connection.quote_table_name(::Delayed::Job.table_name)})
    execute %{DROP FUNCTION #{connection.quote_table_name('delayed_jobs_before_insert_row_tr_fn')} ()}
    execute %(DROP TRIGGER delayed_jobs_after_delete_row_tr ON #{connection.quote_table_name(::Delayed::Job.table_name)})
    execute %{DROP FUNCTION #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')} ()}

    remove_column :delayed_jobs, :next_in_strand
    remove_index :delayed_jobs, name: 'get_delayed_jobs_index'
    add_index :delayed_jobs, %w[run_at queue locked_at strand priority], name: 'index_delayed_jobs_for_get_next'
  end
end
