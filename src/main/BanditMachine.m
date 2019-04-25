classdef BanditMachine <handle
    properties
       robustness
       %last_robustness
       reward
       visit
       
       
       fal_problem
       
       BrSys
       phi
       phi_type
       
       budget_unit
       
       signal
       signalID
       
       count_sim
       
       stop_flag
       result_x
       
       large_robustness
    end
    
    methods
        function this = BanditMachine(BrSys, phi, signalID, b_u, pt)
            this.BrSys = BrSys;
            this.phi = phi;
            
            this.budget_unit = b_u;
            
            this.robustness = intmax;
            %this.last_robustness = intmax;
            this.reward = 0;
            this.visit = 0;
            
            this.signalID = signalID;
            
            this.fal_problem = PartialFP(BrSys,phi,signalID, b_u, pt);
            this.fal_problem.setup_solver('cmaes');
            
            this.phi_type = pt;
            
            this.count_sim = 0;
            this.stop_flag = false;
            this.result_x = [];
            
            this.large_robustness = -1;
        end
        
        
        
        function simulate(this)
            
            
            this.fal_problem.solve();
            this.robustness = this.fal_problem.best_robustness;
            
            status = this.fal_problem.proc_status;
            if status == 1&& this.robustness<0
                this.stop_flag = true;
                this.result_x = this.fal_problem.best_x;
                this.result_x
            end
            
            this.visit = this.visit + 1;
            
            this.count_sim = this.fal_problem.count_sim;
            
            if status == 0 || this.robustness == intmax
                this.reward = 0;
                this.large_robustness = -1;
            else
                if this.robustness> this.large_robustness
                    this.large_robustness= this.robustness;    
                end
                
                
                %if this.last_robustness == intmax || this.robustness >= this.last_robustness
                %this.robustness
               % disp('a')
               % this.large_robustness
                if this.robustness >= this.large_robustness
                    this.reward = 0;
                elseif this.robustness < 0
                    this.reward = 1;
                else
                    this.reward = (this.large_robustness-this.robustness)/this.large_robustness;
                end
                %this.last_robustness = this.robustness;
            end
        end
    end
    
    
    
end