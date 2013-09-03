import_types_from 'envire'
module Rock
    module MapGen
        data_service_type 'MapGeneratorSrv' do
            output_port 'map', ro_ptr('std/vector</envire/BinaryEvent>')
        end

        data_service_type 'MLSSrv' do
            provides MapGeneratorSrv
        end
        data_service_type 'TraversabilitySrv' do
            provides MapGeneratorSrv
        end

        # Data service that is used to tag map generators that provide a single
        # map at startup, and then nothing
        data_service_type 'OneShotSrv'
        
        def OneShotSrv.included(other)
            # Called when the service gets provided by a task or another
            # service. It marks the task as non-reusable
            if other <= Syskit::TaskContext
                other.on :start do |event|
                    event.task.needs_reconfiguration!
                end
            end
        end
    end
end
