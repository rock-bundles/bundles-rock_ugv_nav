require 'models/blueprints/pose'
import_types_from 'odometry'

module SLAM
    data_service_type 'OdometrySrv' do
        provides Base::RelativePoseSrv
        provides Base::PoseDeltaSrv
    end

    # This data service provides contact point of the robot 
    # with its environment.
    data_service_type 'BodyContactStateSrv' do
        output_port 'contact_samples', '/odometry/BodyContactState'
    end
end

using_task_library 'odometry'

module SLAM
    class Odometry < Syskit::Composition
        add Base::OrientationSrv, :as => 'orientation'
        add OdometrySrv, :as => 'odometry'
        export odometry_child.pose_samples_port
        export odometry_child.pose_delta_samples_port
        provides OdometrySrv, :as => 'odometry'

        specialize odometry_child => ::Odometry::Skid do
            add Base::JointsControlledSystemSrv, :as => 'joint_status'
            joint_status_child.connect_to odometry_child
        end

        specialize odometry_child => ::Odometry::ContactPointTask do
            add SLAM::BodyContactStateSrv, :as => 'contact_points'
            contact_points_child.connect_to odometry_child
        end
    end
end

