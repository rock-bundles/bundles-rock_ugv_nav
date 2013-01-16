# High level interface for the navigation layers
class MoveTo < Roby::Task
    abstract
    terminates

    # The starting point, given as an Eigen::Vector3 object. If it is not given,
    # it will be taken from the State, as pose.position
    argument :start_point, :default => from_state.pose.position.of_type(Eigen::Vector3)
    # The goal, given as an Eigen::Vector3 object
    argument :target_point
end

