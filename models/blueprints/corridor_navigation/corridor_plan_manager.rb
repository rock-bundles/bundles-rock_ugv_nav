require 'models/blueprints/corridor_navigation/tasks'
require 'models/tasks/move_to'
require 'base/float'

module Rock
    module CorridorNavigation
        # High level interface for the corridor-based navigation layer
        #
        # It generates a corridor plan from a start position to a goal position,
        # translates that plan into SingleCorridor tasks, selects a path and selects the
        # needed modalities
        class MoveTo < ::MoveTo
            # When the corridor planner has finished, this holds the final plan
            attr_reader :corridor_plan
            # The set of possible paths in +corridor_plan+ as a list of
            # [corridor_idx, entry_point]
            attr_reader :available_paths

            # Creates the subplan needed to move to the given target point using the
            # corridor planner
            def self.as_plan(target_point, start_point = nil)
                options = { :target_point => target_point }
                if start_point
                    options[:start_point] = start_point
                end

                main = new(options)
                planner = main.planned_by(Orocos::CorridorPlanner::Task, :plan_early => false)
                planner.success_event.forward_to(main.update_corridor_event)
                main
            end

            def self.corridor_log
                @corridor_log ||= Pocolog::Logfiles.create(File.join(Roby.app.log_dir, 'selected_corridors'))
            end

            def self.corridor_log_stream
                # Log of the selected corridors
                @corridor_stream ||= corridor_log.stream('controller.selected_corridors', Types::Corridors::Plan, true)
            end

            def initialize(arguments = Hash.new)
                super
                @plan_handler = lambda do |plan|
                    @available_paths = plan.all_paths
                    path = @available_paths[rand(@available_paths.size)]
                    corridor = plan.path_to_corridor(path)
                    [corridor, 'corridor_following']
                end
                
                @corridor_servoing_error_handler = lambda do |context|
                end
                
                @corridor_following_error_handler = lambda do |context|
                    begin
                        cur_following_task = following_child
                        
                        #create copy of current task
                        spec = Orocos::RobyPlugin.requirement_from_name('corridor_following').
                            with_arguments(:target_heading => cur_following_task.target_heading)
                        following  = Orocos::RobyPlugin.require_task(spec)
                        
                        relocalize, _ = Robot.prepare_action(plan, 'relocalize')
                        following.depends_on(relocalize, :consider_in_pending => true)
                        following.should_start_after relocalize.success_event
                        plan.replace(cur_following_task, following)
                        # NOTE: this must be called after the replace, otherwise, we have
                        # a constraint on the new following task, not the old one
                        relocalize.should_start_after cur_following_task
                    rescue Exception => e
                        Robot.info "ERROR #{e.message}"
                        e.backtrace.each do |line|
                            Robot.info "  #{line}"
                        end
                    end
                end
            end

            def plan_handler(&block)
                @plan_handler = block
            end

            def corridor_following_error_handler(&block)
                @corridor_following_error_handler = block
            end
            
            def corridor_servoing_error_handler(&block)
                @corridor_servoing_error_handler = block
            end

            event :corridor_following_error
            on :corridor_following_error do |context|
                @corridor_following_error_handler.call(context)
            end

            event :corridor_servoing_error
            on :corridor_servoing_error do |context|
                @corridor_servoing_error_handler.call(context)
            end
        
            event :update_corridor do |context|
                update_corridor_event.achieve_with(planning_task.respawn)
            end
            on :update_corridor do |event|
                # Drop all the corridors we are managing
                plan.find_tasks(SingleCorridor).with_parent(self).
                    to_a.each do |task|
                        remove_child(task)
                    end

                #workaround the planning task can either be corriudor_planner::Task
                #or a composition with a corridor_planner_child
                plan = nil
                if(planning_task.respond_to?(:result))
                    plan = planning_task.result
                else
                    plan = planning_task.corridor_planner_child.result
                end
                # Add the new corridors. For now, we just randomly pick one and add
                # it as our child
                if plan
                    @corridor_plan = plan
                    # The plan handler is a block that should return an array of the
                    # form
                    #   [corridor, modality]
                    #
                    # where +modality+ is either a string (a definition) or a
                    # requirement object (i.e. Cmp::CorridorServoing,
                    # Cmp::CorridorServoing.with_arguments(:test => 2), ...)
                    path = @plan_handler.call(plan)
                    path.each do |corridor, modality|
                        puts "corridor_plan_manager: #{corridor.median_curve.start_point} => #{corridor.median_curve.end_point}: #{modality}"
                    end

                    # Generate a /corridors/Plan structure that contains the
                    # selected corridors, and save it on a log file
                    #
                    # This sucks. We should be able to have an output port from the
                    # Roby process that can be logged the "normal" way, and/or
                    # displayed live
                    path_as_plan = Types::Corridors::Plan.new
                    path_as_plan.zero!
                    path_as_plan.start_corridor = 0
                    path_as_plan.end_corridor = path.size - 1
                    path.each_with_index do |(corridor, modality), idx|
                        path_as_plan.corridors << corridor
                        if idx != 0
                            conn = Types::Corridors::CorridorConnection.new
                            conn.zero!
                            conn.from_idx = idx - 1
                            conn.from_side = :BACK_SIDE
                            conn.to_idx   = idx
                            conn.to_side = :FRONT_SIDE
                            path_as_plan.connections << conn
                        end
                    end
                    self.class.corridor_log_stream.write(Time.now, Time.now, path_as_plan)

                    # Now create the modality sequence. We add a SingleCorridor
                    # child per corridor, and assign the corridor to it. This task
                    # then depends on the selected modality. The modality task
                    # should pick up the corridor it is supposed to follow from its
                    # parent task directly (i.e. using #parent_task)
                    last_corridor = nil
                    path.each do |corridor, modality|
                        corridor_task = SingleCorridor.new
                        corridor_task.corridor = corridor
                        if modality.respond_to?(:to_str)
                            modality_task = corridor_task.depends_on(Orocos::RobyPlugin.require_task(modality))
                        else
                            modality_task = corridor_task.depends_on(modality)
                        end
                        depends_on corridor_task

                        # The corridor task is finshed if the modality is sucessfully finished
                        modality_task.success_event.forward_to corridor_task.success_event

                        # ... And build a sequence
                        if(modality_task.has_event?(:pose_error))
                            puts("Got a Corridor Follower")
                            # add error handling for corridor_following
                            modality_task.pose_error_event.forward_to self.corridor_following_error_event
                        else
                            puts("Got a corridor Servoer")
                            modality_task.servoing_error_event.forward_to self.corridor_servoing_error_event
                        end
                        
                        if last_corridor
                            last_corridor.success_event.signals corridor_task.start_event
                        end
                        last_corridor = corridor_task
                    end
                    if(!last_corridor)
                        #TODO success might be wrong here
                        emit :success
                    else
                        # This task finishes successfully if the whole chain of modalities has
                        # finished successfully
                        last_corridor.success_event.forward_to success_event
                    end
                else
                    emit :blocked
                end
            end
            event :blocked
        end
    end
end
