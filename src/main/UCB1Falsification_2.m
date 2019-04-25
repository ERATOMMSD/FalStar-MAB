classdef UCB1Falsification_2 <handle
    properties
        
        %basic information
        BrSys
        phi
        
        
        %hyper parameters
        budget
        budget_unit
        
        %config for UCB1
        c
        
        
        %runtime variable
        idx
        umachine1
        umachine2
        ucbvalue = []
        counter
        
        %return information
        falsified
        num_sim
        
        phi_type
        
      %  budget_pre
        
        init_sample
        product_obj
        
        my_robust_fn
        
        params
        
        %rob1
        %rob2
        
        pre_numsim
    end
    
    methods
        function this = UCB1Falsification_2(BrSys, phi, budget, b_u, c, pt)
            this.BrSys = BrSys;
            this.phi = phi;
            
            this.params = BrSys.GetBoundedDomains();
            
            this.budget = budget;
            this.budget_unit = b_u;
            this.c = c;
            
            this.idx = 1;
            this.umachine1 = BanditMachine(BrSys, phi, 1, b_u, pt);
            this.umachine2 = BanditMachine(BrSys, phi, 2, b_u, pt);
            
            
            this.ucbvalue(1) = 0;
            this.ucbvalue(2) = 0;
            
            this.falsified = 0;
            this.num_sim = 0;
            this.counter = 0; %to count the total visit
            
            this.phi_type = pt;
            
           % this.budget_pre = b_pre;
            this.product_obj = intmax;
            
            
            this.init_sample = [];
            this.my_robust_fn = BrSys.GetRobustSatFn(phi, 1, this.params, 0);
            
            %this.obj_best = intmax;
            %this.rob1 = intmax;
            %this.rob2 = intmax;
            
            this.pre_numsim = 0;
        end
        
        
        
        function solve(this)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            for b = 1:this.budget
                if this.idx == 1
                    this.umachine1.simulate();
                else
                    this.umachine2.simulate();
                end
                this.counter = this.counter + 1;
                this.num_sim = this.umachine1.count_sim + this.umachine2.count_sim;
                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                
                
                if this.umachine1.stop_flag|| this.umachine2.stop_flag
                    this.falsified = 1;
                    
                    break;
                else
                    this.ucbvalue(1) = this.UCB1(this.umachine1);
                    this.ucbvalue(2) = this.UCB1(this.umachine2);
                    this.ucbvalue
                    [~,this.idx] = max(this.ucbvalue);
                    
                   % this.idx
                end
                
                
            end
            this.num_sim = this.num_sim + this.pre_numsim;
        end
        
        function uv = UCB1(this, umachine)
           % umachine.reward
            uv = umachine.reward + this.c*sqrt((2.0*log(this.counter+1))/(umachine.visit+1));
        end
        
        
      
        
        
    end
end