classdef UCB1Falsification <handle
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
        
        budget_pre
        
        init_sample
        product_obj
        
        my_robust_fn
        
        params
        
        rob1
        rob2
        
        pre_numsim
    end
    
    methods
        function this = UCB1Falsification(BrSys, phi, budget, b_u, c, pt, b_pre)
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
            
            this.budget_pre = b_pre;
            this.product_obj = intmax;
            
            
            this.init_sample = [];
            this.my_robust_fn = BrSys.GetRobustSatFn(phi, 1, this.params, 0);
            
            %this.obj_best = intmax;
            this.rob1 = intmax;
            this.rob2 = intmax;
            
            this.pre_numsim = 0;
        end
        
        
        
        function solve(this)
            
            
            %seperate two dimensions
            if this.check_x0() ~= 1
                this.falsified = 0;
                this.num_sim = this.pre_numsim;
                return;
            end
            
            %rob = this.umachine1.simulate();
            %if rob < 0
            %    this.falsified = 1;
            %    return;
            %end
            %rob = this.umachine2.simulate();
            %if rob < 0
            %    this.falsified = 1;
            %    return;
            %end
            %this.counter = this.counter + 2;
            
            
            rob1__ = intmax;
            rob2__ = intmax;
            for b = 1:this.budget
                if this.idx == 1
                    rob1__ = this.umachine1.simulate();
                else
                    rob2__ = this.umachine2.simulate();
                end
                this.counter = this.counter + 1;
                this.num_sim = this.umachine1.count_sim + this.umachine2.count_sim;
               % this.obj_best = min(rob1,rob2);
                
                
                if rob1__< this.rob1
                    rob1__
                    this.rob1 = rob1__;
                end
                if rob2__ < this.rob2
                    rob2__
                    this.rob2 = rob2__;
                end
                if this.rob1<0||this.rob2 < 0
                    this.falsified = 1;
                    
                    break;
                else
                    
                    this.ucbvalue(1) = this.UCB1(this.umachine1);
                    this.ucbvalue(2) = this.UCB1(this.umachine2);
                    [~,this.idx] = max(this.ucbvalue);
                end
                
                
            end
            this.num_sim = this.num_sim + this.pre_numsim;
        end
        
        function uv = UCB1(this, umachine)
            uv = umachine.reward + this.c*sqrt((2.0*log(this.counter))/umachine.visit);
        end
        
        
        function bestf = check_x0(this)
            
            %params = this.BrSys.GetBoundedDomains();
            ranges = this.BrSys.GetParamRanges(this.params);
            if strcmp(this.phi_type, 'or')
                opts = cmaes();
                opts.Seed = round(rem(now,1)*1000000);
                

                opts.LBounds = ranges(:,1);
                opts.UBounds = ranges(:,2);
                opts.StopIter = this.budget_pre;

                x0 = zeros(1, numel(this.params));
                [i_s,~,this.pre_numsim,~,~, best] = cmaes(@(x)this.lead_to_neg(x), x0', [], opts);
                bestf = best.f;

                this.init_sample = i_s;
            else
                this.init_sample = zeros(1, numel(this.params));
            end
        end
        
        function neg = lead_to_neg(this, x)
            global or_product;
            
            if this.product_obj == 1
                neg = this.product_obj;
            else
                this.my_robust_fn(x);
                neg = or_product;
                
                if neg < this.product_obj
                    
                    this.product_obj = neg;
                end
            end
            
        end
        
        
    end
end