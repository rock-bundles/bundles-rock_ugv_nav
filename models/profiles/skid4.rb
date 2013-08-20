require 'models/blueprints/odometry'
require 'models/blueprints/control'
require 'models/blueprints/corridor_navigation'
require 'models/blueprints/map_gen/local_map'
using_task_library 'skid4_control'
using_task_library 'odometry'

module Rock
    module UGVNav
        profile 'Skid4' do
            use Base::Motion2DControlledSystemSrv =>
                Base::ControlLoop.use('controller' => Skid4Control::SimpleController)
            use SLAM::OdometrySrv =>
                SLAM::Odometry.use('odometry' => Odometry::Skid4OdometryTask)

            define 'joystick_drive', Base::ControlLoop.
                prefer_specializations('controller' => Base::Motion2DControllerSrv,
                                       'controlled_system' => Base::Motion2DControlledSystemSrv).
                use('controller' => Controldev::JoystickTask)
            define 'local_navigation', Rock::CorridorNavigation::Servoing.use(
                'pose' => SLAM::OdometrySrv)
            define 'explore', Rock::CorridorNavigation::Explore.use(
                'pose' => SLAM::OdometrySrv)
            define 'local_map', Rock::MapGen::LocalMap.use('pose' => SLAM::OdometrySrv)
        end
    end
end
