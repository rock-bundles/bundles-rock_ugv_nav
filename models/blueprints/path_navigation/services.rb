module Rock
    module PathNavigation
        data_service_type 'PathPlannerSrv' do
            input_port 'map', '/RTT/extras/ReadOnlyPointer</std/vector</envire/BinaryEvent>>'
            output_port 'path', '/std/vector</base/Trajectory>'
        end
        data_service_type 'TargetPositionSrv' do
            output_port 'target_position', '/base/Vector3d'
        end
        data_service_type 'DynamicPathPlannerSrv' do
            provides PathPlannerSrv
            input_port 'robot_pose', '/base/samples/RigidBodyState'
            input_port 'target_pose', '/base/Vector3d'
        end
    end
end
