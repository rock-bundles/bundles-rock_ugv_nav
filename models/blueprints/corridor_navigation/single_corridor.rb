module Rock
    module CorridorNavigation
        # Task representing a single corridor
        #
        # These tasks start as non-executable. It is the job of a modality selection
        # engine to mark them as executable when a modality got selected
        class SingleCorridor < Roby::Task
            terminates

            # The corridor that this task represents, as a
            # Types::CorridorPlanner::Corridor instance
            attr_accessor :corridor
        end
    end
end

