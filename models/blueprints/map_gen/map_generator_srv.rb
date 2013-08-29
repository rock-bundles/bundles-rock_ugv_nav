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
    end
end
