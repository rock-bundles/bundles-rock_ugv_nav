using_task_library 'eslam'

module Rock
    module MapGen
        class Eslam < Syskit::Composition
            add SLAM::BodyContactStateSrv, :as => 'contact_state'
            add Base::OrientationSrv, :as => 'orientation'
            add Base::LaserRangeFinderSrv, :as => 'laser'
            add Base::RelativePoseSrv, :as => 'odometry'

            add Eslam::Task, :as => 'eslam'

            export eslam_child.pose_samples_port
            provides Base::GlobalPoseSrv, :as => 'pose'
            export eslam_child.map
            provides MapGeneratorSrv, :as => 'map'

            contact_state_child.connect_to eslam_child
            imu_child.connect_to eslam_child.orientation_samples_port
            laser_child.connect_to eslam_child

            conf 'localization',
                'eslam' => ['default', 'localization']
            conf 'mapping',
                'eslam' => ['default', 'mapping']

            # TODO: synchronize the eSLAM start pose with the current pose
            # This is not strictly required, but makes the eSLAM map more
            # "north-aligned"
        end
    end
end

