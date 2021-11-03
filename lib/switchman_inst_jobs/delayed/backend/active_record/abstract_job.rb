module SwitchmanInstJobs
  module Delayed
    module Backend
      module ActiveRecord
        module AbstractJob
          module ClassMethods
            def current_switchman_shard
              connected_to_stack.reverse_each do |hash|
                return hash[:switchman_shard] if hash[:switchman_shard] && hash[:klasses].include?(connection_classes)
              end

              ::ActiveRecord::Base.current_switchman_shard.delayed_jobs_shard
            end
          end

          def self.prepended(base)
            base.singleton_class.prepend(ClassMethods)

            base.sharded_model
          end
        end
      end
    end
  end
end
