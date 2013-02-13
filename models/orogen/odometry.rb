require 'models/blueprints/pose'
require 'models/blueprints/odometry'

class Odometry::Skid4OdometryTask
    # Additional information for the transformer's automatic configuration
    transformer do
        associate_frame_to_ports "body", "odometry_delta_samples"
        transform_output "odometry_samples", "body" => "odometry"
       # transform_input "orientation_samples", "imu" => "world"
    end
    
    provides SLAM::OdometrySrv, :as => 'odometry',
        'pose_samples' => 'odometry_samples', 'pose_delta_samples' => 'odometry_delta_samples'
end

class Odometry::ContactPointTask
    # Additional information for the transformer's automatic configuration
    transformer do
        associate_frame_to_ports "body", "odometry_delta_samples"
        transform_output "odometry_samples", "body" => "odometry"
       # transform_input "orientation_samples", "imu" => "world"
    end
    
    provides SLAM::OdometrySrv, :as => 'odometry',
        'pose_samples' => 'odometry_samples', 'pose_delta_samples' => 'odometry_delta_samples'
end


SLAM::Odometry.specialize 'odometry' => Odometry::ContactPointTask do
    add SLAM::BodyContactStateSrv, :as => 'contact_points'
    contact_points_child.connect_to(odometry_child)
end
