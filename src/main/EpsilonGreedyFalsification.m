classdef EpsilonGreedyFalsification < handle
    
    properties
        %basic information
        BrSys
        phi
        
        %hyper parameters
        budget
        budget_unit
        
        %config for Epsilon
        c
        
        
        %runtime variable
        idx
        umachine1
        umachine2
        %epsilonvalue = []
        %counter
        
        
        %return information
        falsified
        num_sim
        
        phi_type
        %budget_pre
        
        init_sample
        product_obj
        
        my_robust_fn
        
        params
        
        rob1
        rob2
        
        %pre_numsim
        
        larger_idx
    end
    
    methods
        function this = EpsilonGreedyFalsification(BrSys, phi, budget, b_u, c, pt)
            this.BrSys = BrSys;
            this.phi = phi;
            
            this.params = BrSys.GetBoundedDomains();
            
            this.budget = budget;
            this.budget_unit = b_u;
            this.c = c;
            
            this.idx = 1;
            this.umachine1 = BanditMachine(BrSys, phi, 1, b_u, pt);
            this.umachine2 = BanditMachine(BrSys, phi, 2, b_u, pt);
            
            this.falsified = 0;
            this.num_sim = 0;
            
            this.phi_type = pt;
            
            %this.budget_pre = b_pre;
            this.product_obj = intmax;
            
            this.init_sample = [];
            this.my_robust_fn = BrSys.GetRobustSatFn(phi, 1, this.params, 0);
            
            this.rob1 = intmax;
            this.rob2 = intmax;
            
            %this.pre_numsim = 0;
            
            this.larger_idx = 1;
            
            %this.epsilonvalue(1) = 0;
            %this.epsilonvalue(2) = 0;
            
        end
        
        function solve(this)

            for b = 1:this.budget
                if this.idx == 1
                    this.umachine1.simulate();
                else
                    this.umachine2.simulate();
                end
                this.num_sim = this.umachine1.count_sim + this.umachine2.count_sim;
                
                if this.umachine1.stop_flag||this.umachine2.stop_flag
                    this.falsified = 1;
                    break;
                else
                    this.idx = this.choose();
                    this.idx
                end
                
               
                
                
            end
                   
            
        end
        
        function idx = choose(this)
            rng('default')
            rng(round(rem(now,1)*1000000))
            samp = rand();
            
            prob = (1-this.c)+this.c/2.0;
            this.umachine1.reward
            
            r_list = [this.umachine1.reward this.umachine2.reward];
            [~,idx__] = max(r_list);
            if samp < prob
                idx = idx__;
            else
                idx = 3-idx__;
            end
                
        end
        
 %       function bestf = check_x0(this)
            
            %params = this.BrSys.GetBoundedDomains();
%            ranges = this.BrSys.GetParamRanges(this.params);
%            if strcmp(this.phi_type, 'or')
%                opts = cmaes();
%                opts.Seed = round(rem(now,1)*1000000);
                

%                opts.LBounds = ranges(:,1);
%                opts.UBounds = ranges(:,2);
%                opts.StopIter = this.budget_pre;

 %               x0 = zeros(1, numel(this.params));
%                [i_s,~,this.pre_numsim,~,~, best] = cmaes(@(x)this.lead_to_neg(x), x0', [], opts);
%                bestf = best.f;

 %               this.init_sample = i_s;
 %           else
 %               this.init_sample = zeros(1, numel(this.params));
 %           end
 %       end
        
%        function neg = lead_to_neg(this, x)
%            global or_product;
            
%            if this.product_obj == 1
%                neg = this.product_obj;
%            else
%                this.my_robust_fn(x);
%                neg = or_product;
%                
%                if neg < this.product_obj
%                    
%                    this.product_obj = neg;
%                end
%            end
            
%        end
        
        
    end
end