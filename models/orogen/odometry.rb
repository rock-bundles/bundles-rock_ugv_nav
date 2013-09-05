require 'models/blueprints/pose'
require 'models/blueprints/odometry'

class Odometry::Generic
    provides SLAM::OdometrySrv, :as => 'odometry',
        'pose_samples' => 'odometry_samples', 'pose_delta_samples' => 'odometry_delta_samples'

    transformer do
        associate_frame_to_ports "body", "odometry_delta_samples"
        transform_output "odometry_samples", "body" => "odometry"
    end
end


