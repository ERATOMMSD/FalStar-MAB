classdef PartialFP < FalsificationProblem
    properties
        
        maxIter;
        mI_unit;
        signalID;
        my_robust_fn
        
        new_run
        
        phi_type;
        
        count_sim;
        
        best_robustness;
        best_x;
        
        proc_status;
        pre_robustness;
        
        init_sample;
        
        objective_pre;
        obj_best_pre;
        
        obj_best_robustness;
        
    end
    
    methods
        function this = PartialFP(BrSet, phi, signalID, mI, pt)
            
            this = this@FalsificationProblem(BrSet, phi);
            this.signalID = signalID;
            this.my_robust_fn = BrSet.GetRobustSatFn(phi, this.signalID, this.params, this.T_Spec);
            this.new_run = true;
            this.maxIter = 0;
            this.mI_unit = mI;
            this.init_sample = this.init_sample_generator();
            
            this.phi_type = pt;
            
            this.count_sim = 0;
            this.best_robustness = intmax;
            this.best_x = [];
            this.proc_status = 0;
            this.pre_robustness = intmax;
            
            this.objective_pre = @(x) (objective_wrapper_pre(this,x));
            this.obj_best_pre = inf;
            this.obj_best_robustness = inf;
         %   this.product_obj = intmax;
            
           % this.budget_pre = 
        end
        
        function i_sample = init_sample_generator(this)
            rng('default')
            rng(round(rem(now,1)*1000000))
            i_sample = [];
            for i = 1: numel(this.params)
                is__ = this.lb(i) + rand()*(this.ub(i)-this.lb(i));
                i_sample = [i_sample is__];
            end
        end
        
        function res = solve(this)
            rfprintf_reset();
            
            % reset time
            this.ResetTimeSpent();
            
            % create problem structure
            problem = this.get_problem();
                        
            switch this.solver
                case 'init'
                    res = FevalInit(this);
                    
                case 'basic'
                    res = this.solve_basic();
                    
                case 'global_nelder_mead'
                    res = this.solve_global_nelder_mead();
                    
                case 'cmaes'
                    % adds a few more initial conditions
                    nb_more = 10*numel(this.params)- size(this.x0, 2);
                    if nb_more>inf
                        Px0 = CreateParamSet(this.BrSet.P, this.params,  [this.lb this.ub]);
                        Px0 = QuasiRefine(Px0, nb_more);
                        this.x0 = [this.x0' GetParam(Px0,this.params)]';
                    end
                    
                    this.maxIter = this.maxIter + this.mI_unit;
                    this.solver_options.StopIter = this.maxIter;
                    
                    
                    
                    this.solver_options.SaveFilename = strcat('variablescmaes_', num2str(this.signalID),'.mat');
                    
                    if strcmp(this.phi_type,'and')
                        this.proc_status = 1;
                    end
                    
                    
                    if this.new_run
                        this.solver_options.Resume = 0;
                        this.new_run = false;
                        sd = round(rem(now,1)*1000000);
                        this.solver_options.Seed = sd;
                    else
                        this.solver_options.Resume = 1;
                    end
                    
                    
                    
                    if this.proc_status == 0
                        [x, fval, counteval, stopflag, out, bestever] = cmaes(this.objective_pre, this.init_sample', [], this.solver_options);

                        if bestever.f< this.pre_robustness
                            this.pre_robustness = bestever.f;
                        end
                        stopflag_str = cell2mat(stopflag);
                        f1 = contains(stopflag_str, 'equalfunvals');
                        f2 = this.pre_robustness<0;
                        if f2
                            this.new_run = true;
                            this.maxIter = 0;
                            this.init_sample = bestever.x;
                            this.proc_status = 1;
                            this.best_robustness = intmax;
                            this.obj_best_robustness = inf;
                        end
                        if f1&&~f2
                            this.new_run = true;
                            this.maxIter = 0;
                            this.init_sample = this.init_sample_generator();
                            this.pre_robustness = intmax;
                            this.obj_best_pre = inf;
                        end
                        
                        %if f1&&f2
                        %    this.new_run = true;
                        %    this.maxIter = 0;
                        %    this.init_sample = x;
                        %    this.proc_status = 1;
                        %elseif ~f1&&f2
                        %    this.new_run = true;
                        %    this.maxIter = 0;
                        %    this.init_sample = this.init_sample_generator();
                        %elseif f1&&~f2
                        %    this.new_run = true;
                        %    this.maxIter = 0;
                        %    this.init_sample = this.init_sample_generator();
                        %else 
                        %end


                    else
                        [x, fval, counteval, stopflag, out, bestever] = cmaes(this.objective, this.init_sample', [], this.solver_options);
                        if bestever.f< this.best_robustness
                            this.best_robustness = bestever.f;
                            this.best_x = bestever.x;
                        end
                        stopflag_str = cell2mat(stopflag);
                        f1 = contains(stopflag_str, 'equalfunvals');
                        f2 = this.best_robustness<0;
                        if f1&&~f2
                            this.new_run = true;
                            this.maxIter = 0;
                            this.init_sample = this.init_sample_generator();
                            this.proc_status = 0;
                            this.pre_robustness = intmax;
                            this.best_robustness = intmax;
                            this.obj_best_pre = inf; 
                            this.obj_best_robustness = inf;
                            
                            
                        end

                    end

                    this.count_sim = counteval;
                     
                    res = struct('x',x, 'fval',fval, 'counteval', counteval,  'stopflag', stopflag, 'out', out, 'bestever', bestever);
                    this.res=res;
		    
		    
                    
                case 'ga'
                    res = solve_ga(this, problem);
                    this.res = res;
                    
                case {'fmincon', 'fminsearch', 'simulannealbnd'}
                    [x,fval,exitflag,output] = feval(this.solver, problem);
                    res =struct('x',x,'fval',fval, 'exitflag', exitflag, 'output', output);
                    this.res=res;
                    
                case 'optimtool'
                    problem.solver = 'fmincon';
                    optimtool(problem);
                    res = [];
                    return;

                case 'binsearch'
                    res = solve_binsearch(this);
                    this.res = res;

                otherwise
                    res = feval(this.solver, problem);
                    this.res = res;
            end
            
            %this.DispResultMsg(); 
            
    
            
        end
        
        function obj = my_objective_fn(this, x)
            obj = min(this.my_robust_fn(x));
        end
        
        function fval = objective_wrapper(this, x)
            
            if this.obj_best_robustness<0
                fval = this.obj_best_robustness;
            else
            % calling actual objective function
                fval = this.my_objective_fn(x);

                if fval < this.obj_best_robustness
                    this.obj_best_robustness = fval;
                end
                
                % logging and updating best
                this.LogX(x, fval);
                %this.count_sim = this.count_sim + 1;
                
                
                % update status
                if rem(this.nb_obj_eval,this.freq_update)==0
                    this.display_status();
                end
            end
            
            
        end
        
        
        function fval = objective_wrapper_pre(this, x)
            global rob_pre;
            if this.obj_best_pre<0
                fval = this.obj_best_pre;
            else
            
                this.my_objective_fn(x);
                
                
                
                fval = rob_pre;
                
                if fval<this.obj_best_pre
                    this.obj_best_pre = fval;
                end
                
                this.LogX(x, fval);
            end
            
            
        end
        
        
        
    end
end