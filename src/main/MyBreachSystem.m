classdef MyBreachSystem < BreachSet
    %BreachSystem  A simplified API class for Breach.
    %
    % It combines a system structure (Sys) with a parameter set (P)
    % into one object so that basic operations can be done in one
    % command instead of several and with fewer arguments. BreachSystem
    % class is derivated from BreachSet. Type help BreachSet to view
    % properties and methods of the parent class.
    %
    % BreachSystem Properties
    %   Specs  - a set of Signal Temporal Logic (STL) formulas.
    %
    %
    % BreachSystem methods
    %   Sim           - Simulate the system for some time using every parameter vectors.
    %   SetTime       - Set a default time for simulation (array or end time)
    %   GetTime       - Get default time for simulation
    %   AddSpec       - Add a specification to the system
    %   CheckSpec     - Checks (return robust satisfaction of) a given specification or all added specs
    %   PlotRobustSat - Plots robust satisfaction of a given STL formula against time
    %   PlotRobustMap - Plots (1d or 2d) robust satisfaction against parameter values
    %   RunGUI        - Open Breach GUI, allowing for interactive exploration of parameters, traces and specifications
    %
    %   See also BreachSet.
    
    properties
        Sys                   % Legacy Breach system structure
        Specs               % A set (map) of STL formulas
        ParamSrc=containers.Map()
        use_parallel=0 % 
        InitFn = ''           % Initialization function 
    end
    
    methods
        
        %% Constructor
        function this = BreachSystem(varargin)
            this.Specs = containers.Map();
            
            switch nargin
                case 0 % do nothing
                case 1 % Should be a Sys structure
                    
                    inSys = varargin{1};
                    if isaSys(inSys)
                        this.Sys = inSys;
                        this.P = CreateParamSet(this.Sys);
                    else
                        error('BreachObject with one argument assumes that the argument is a system structure.')
                    end
                otherwise % creates an extern system
                    if ~(exist(varargin{1})==4) % tests if the first argument is a Simulink model
                        this.Sys = CreateExternSystem(varargin{:});
                    else
                        warning('First argument is the name of a Simulink model - consider using BreachSimulinkSystem instead');
                    end
            end
            
            this.SignalRanges = [];
            if (isaSys(this.Sys))
                this.P = CreateParamSet(this.Sys);
            end
        end
        
        function SetupParallel(this)
            this.use_parallel = 1;
            this.Sys.Parallel =1;
            gcp;
        end
        
        function this = SetInitFn(this,Fn)
            if isa(Fn, 'function_handle')
                f = functions(Fn);
                this.InitFn = f.function;
            else
                try
                    evalin('base', Fn);
                    this.InitFn = Fn;
                catch
                    error('Argument of SetInitFn must be a valid function handle or function or script name.');
                end
            end
        end
        
        %% Parameters
        % Get and set default parameter values (defined in Sys)
        
        function values = GetDefaultParam(this, params)
            % Get default parameter values (defined in Sys)
            values = GetParam(this.Sys,params);
        end
        
        function SetDefaultParam(this, params, values)
            % Set default parameter values (defined in Sys)
            this.Sys = SetParam(this.Sys,params, values);
        end
        
        function SetP(this,P)
            % SetP Sets legacy parameter structure
            if isaP(P)
                this.P =P;
            else
                error('Argument should a Breach legacy parameter structure.');
            end
            
        end
        
        function ResetSampling(this)
            % ResetSampling
            this.P = CreateParamSet(this.Sys);
            this.CheckinDomain();
        end
        
        %% Simulation
        function SetTime(this,tspan)
            this.Sys.tspan = tspan;
        end
        
        function time = GetTime(this)
            time = this.Sys.tspan;
        end
        
        function Sim(this,tspan)
            % BreachSystem.Sim(time) Performs a simulation from the parameter
            % vector(s) defined in P
            evalin('base', this.InitFn);
            this.CheckinDomainParam();
            if nargin==1
                tspan = this.Sys.tspan;
            end
            this.P = ComputeTraj(this.Sys, this.P, tspan);
            this.CheckinDomainTraj();
        end
        
        %% Specs
        function phi = AddSpec(this, varargin)
            % AddSpec Adds a specification
            global BreachGlobOpt
            if isa(varargin{1},'STL_Formula')
                phi = varargin{1};
            elseif ischar(varargin{1})
                phi_id = MakeUniqueID([this.Sys.name '_spec'],  BreachGlobOpt.STLDB.keys);
                phi = STL_Formula(phi_id, varargin{1});
            end
                     
            % checks signal compatibility
            [~,sig]= STL_ExtractPredicates(phi);
            i_sig = FindParam(this.Sys, sig);
            sig_not_found = find(i_sig>this.Sys.DimP, 1);
            if ~isempty(sig_not_found)
                error('Some signals in specification are not part of the system.')
            end
            
            this.Specs(get_id(phi)) = phi;
            
            % Add property params
            params_prop = get_params(phi);
            params_names =  fieldnames(params_prop);
            if ~isempty(params_names)
                [~, stat] = FindParam(this.P, params_names);
                p_not_found = params_names( stat==0 )';
                this.SetParamSpec(p_not_found, cellfun(@(c) (params_prop.(c)), p_not_found),1);
            end
        end
        
        function SetSpec(this,varargin)
            this.Specs = containers.Map();
            this.AddSpec(varargin{:});
        end
        
        function val = CheckSpec(this, spec,t_spec)
            if ~exist('spec','var')
                spec = this.Specs.values;
                spec = spec{1};
            else
                if iscell(spec)
                    for cur_spec = spec
                        this.AddSpec(cur_spec{1});
                    end
                else
                    spec = this.AddSpec(spec);
                end
            end
            
            if ~exist('t_spec', 'var')
                t_spec= 0;
            end
            
            %  TODO better check if property has been evaluated already
            %  (check parameter changes)
            %
            if isfield(this.P, 'props_names')&&(nargin<=2) && size(this.P.props_values,2) == size(this.P.pts,2)
                iprop = find(strcmp(get_id(spec), this.P.props_names));
            else
                iprop = 0;
                if isfield(this.P, 'props_names')
                    this.P= SPurge_props(this.P);
                end
            end
            
            if iprop % if values exists, get rid of it (we'll reuse another time)
                idx_wo_iprop = 1:size(this.P.props_values,1)~=iprop;
                this.P.props_values = this.P.props_values(  idx_wo_iprop,: );
                this.P.props_names = this.P.props_names(  idx_wo_iprop );
                this.P.props  = this.P.props(  idx_wo_iprop );
            end
            [this.P, val] = SEvalProp(this.Sys,this.P,spec,  t_spec);
            this.addStatus(0, 'spec_evaluated', 'A specification has been evaluated.')
       
            % TODO? option somewhere to  sort satisfaction values? 
        end
        
        function [Bpos, Bneg] = FilterSpec(this, phi)
            % FilterSpec Separate parameters and trajectories satisfying and violating a
            % specification
            %
            
            if ~exist('phi', 'var')
                phi = this.Specs.values;
                phi = phi{1};
            end
            
            sat_values = this.CheckSpec(phi);
            Bpos = [];
            Bneg = [];
            ipos = find(sat_values>=0);
            ineg = find(sat_values<0);
            
            if ~isempty(ipos)
                Bpos = this.copy();
                Bpos.P = Sselect(Bpos.P, ipos);
            end
            
            if ~isempty(ineg)
                Bneg = this.copy();
                Bneg.P = Sselect(Bneg.P, ineg);
            end
        end
        
        function [rob, tau] = GetRobustSat(this, phi, signalID, params, values, t_phi)
            % Monitor spec on trajectories - run simulations if not done before
            global or_product;
            if nargin < 5
                t_phi = 0;
            end
            if nargin==1
                phi = this.spec;
                params = {};
                values = [];
            end
            
            if nargin==2
                params = {};
                values = [];
            end
            
            if nargin==3
                t_phi = params;
                params = {};
                values = [];
            end
            
            if ~isempty(params)
                this.P = SetParam(this.P, params, values);
            end
            
            this.CheckinDomainParam();
            Sim(this);
            this.CheckinDomainTraj();
            
            % FIXME: this is going to break with multiple trajectories with
            % some of them containing NaN -
            if any(isnan(this.P.traj{1}.X))
                tau = t_phi;
                rob = t_phi;
                rob(:) = NaN;
            else
                [rob, tau] = My_STL_Eval(this.Sys, phi, signalID, this.P, this.P.traj,t_phi);
            end
        end
        
        function [robfn, BrSys] = GetRobustSatFn(this, phi, signalID, params, t_phi)
            % Return a function of the form robfn: p -> rob such that p is a
            % vector of values for parameters and robfn(p) is the
            % corresponding robust satisfaction
            
            if ~exist('t_phi', 'var')
                t_phi =0;
            end
            
            BrSys = this.copy();
            
            if ischar(phi)
                this__phi__ = STL_Formula('this__phi__', phi);
                robfn = @(values) GetRobustSat(BrSys, this__phi__, signalID, params, values, t_phi);
            else
                robfn = @(values) GetRobustSat(BrSys, phi, signalID, params, values,t_phi);
            end
            
        end
        
        function PlotRobustSat(this, phi, depth, tau, ipts)
            % Plots satisfaction signal
            
            % check arguments
            if(~exist('ipts','var')||isempty(ipts))
                ipts = 1;
            end
            
            if(~exist('tau','var')||isempty(tau)) % also manage empty cell
                tau = [];
            end
            
            if ~exist('depth','var')
                depth = inf;
            end
            
            gca;
            SplotSat(this.Sys,this.P, phi, depth, tau, ipts);
            
        end
        
        function PlotSatParams(this, phi, params, varargin)
            % BreachSet.PlotSatParams(req, params)
            
            % default options
            opt.DispTitle = true;  
            opt = varargin2struct(opt, varargin{:});
         
           if ischar(params)
               params = {params};
           end
            
            [valu, pvalu, val, pval] = this.GetSatValues(phi, params);
            if isempty(valu)
               warning('PlotSatParams:SpecNotEval','The specification has not yet been evaluated - use CheckSpec');
            end
            
            iparam = FindParam(this.P, params);
       
            switch numel(params)
                case 1
                    x = pvalu(1,:) ;   % this.P.pts(iparam(1),:);
                    y = zeros(size(x));
                    scatter2dPlot(x,y,valu);
                    xlabel(params{1}, 'Interpreter', 'None');
                    ylabel('');
                    zlabel('');
                case 2
                    x = pvalu(1,:);
                    y = pvalu(2,:);
                    
                    scatter2dPlot(x,y,valu);
                    xlabel(params{1}, 'Interpreter', 'None');
                    ylabel(params{2}, 'Interpreter', 'None');
                    zlabel('');

                case 3
                    x = pvalu(1,:);
                    y = pvalu(2,:);
                    z = pvalu(3,:);
                    
                    scatter3dPlot(x,y,z,valu);
                    xlabel(params{1}, 'Interpreter', 'None');
                    ylabel(params{2}, 'Interpreter', 'None');
                    zlabel(params{3}, 'Interpreter', 'None');
            end

            grid on;
            if ~isempty(valu)
                title_st = [get_id(phi) ' satisfied by '...
                    num2str(numel(find(valu(1,:)>0))) '/' num2str(size(valu,2))
                    ];
                title(title_st, 'Interpreter', 'None');
            end
            
            %% Datacursor mode customization
            h = datacursormode(gcf);
            h.UpdateFcn = @myupdatefcn;
            h.SnapToDataVertex = 'on';
            datacursormode on
            
            cm = uicontextmenu;
            m1 = uimenu(cm, 'Label', 'Plot signals', 'Callback', @ctxtfn_plot_signals);
            m2 = uimenu(cm, 'Label', ['Plot ' get_id(phi)], 'Callback', @(o,e)ctxtfn_plot_robust(phi,o,e));
            m_top = uimenu(cm, 'Label', 'Sub-formulas');
            
            subs = STL_Break(phi,2); 
            stack = subs(1:end-1);
            next_stack = [];
           while ~isempty(stack) 
              % pop 
              subphi = stack(1);
              stack = stack(2:end); 
              uimenu(m_top, 'Label', ['Plot ' get_id(subphi)], 'Callback', @(o,e)ctxtfn_plot_robust(subphi,o,e));
              subs = STL_Break(subphi,2); 
              next_stack = [next_stack subs(1:end-1)];
              if isempty(stack)&&~isempty(next_stack)
                  m_top = uimenu(m_top, 'Label', 'Sub-formulas');
                  stack = next_stack;
                  next_stack = [];
              end
            end
            
            % sub-menus
            set(h, 'UIContextMenu', cm);
            signals = STL_ExtractSignals(phi);
            
            function ctxtfn_plot_signals(o,e)
                if isfield(this.P,'idx_tipped')
                    ipts = this.P.idx_tipped(1);
                    figure;
                    this.PlotSignals( signals, ipts, [], true); % plots signals involved in formula on the same axe
                end
            end

            function ctxtfn_plot_robust(spec, o,e)
                if isfield(this.P,'idx_tipped')
                    ipts = this.P.idx_tipped(1);
                    BreachPlotSat(this, spec, inf , [], ipts); % plots signals involved in formula on the same axe
                end
            end
            
            function [txt] = myupdatefcn(obj,event_obj)
                
                pos = event_obj.Position;
                
                switch numel(params)
                    case 1 
                    idx = ismember(pval', pos(1),'rows')';
                    txt = {[params{1} ':' num2str(pos(1))],...
                              ['Rob: ',num2str(val(idx))] ...
                              };
                    case 2
                    idx = ismember(pval', pos(1:2),'rows')';
                    txt = {[params{1} ':' num2str(pos(1))],...
                              [params{2} ': ',num2str(pos(2))],...
                              ['Rob: ',num2str(val(idx))] ...
                              };
                    
                    case 3
                    idx = ismember(pval', pos(1:3),'rows')';
                    txt = {[params{1} ':' num2str(pos(1))],...
                              [params{2} ': ',num2str(pos(2))],...
                              [params{3} ': ',num2str(pos(3))],...
                              ['Rob: ',num2str(val(idx))] ...
                              };
                end
                this.P.idx_tipped = find(idx);
                
          end  
            
            function scatter2dPlot(x,y,val)
                
                hold on
                grid on;
                if isempty(val)
                        scatter(x,y);
                else
                    vali = val(1,:)';
                    clim = sym_clim(vali);
                    if diff(clim)>0
                        set(gca, 'CLim',clim );
                    end
                    colormap([ 1 0 0; 0 1 0 ]);
                    %colormap(clim);
                    scatter(x,y, 40, vali, 'filled');
                    
                    if size(val,1)>1
                        for il = 2:size(val,1)
                            vali = val(il, :)';
                            i_not_nan = find(~isnan(vali));
                            scatter(x(i_not_nan),y(i_not_nan), 20, vali(i_not_nan), 'filled');
                        end
                    end
                end
            end
            
            function scatter3dPlot(x,y,z,val)
                
                hold on
                grid on;
                if isempty(val)
                    scatter3(x,y,z);
                else
                    
                    vali = val(1,:)';
                    clim = sym_clim(vali);
                    if diff(clim)>0
                        set(gca, 'CLim',clim );
                    end
                    colormap([ 1 0 0; 0 1 0 ]);
                    scatter3(x,y,z, 40, vali, 'filled');
                    
                    if size(val,1)>1
                        for il = 2:size(val,1)
                            vali = val(il, :)';
                            i_not_nan = find(~isnan(vali));
                            scatter3(x(i_not_nan),y(i_not_nan),z(i_not_nan), 20, vali(i_not_nan), 'filled');
                        end
                    end
                end
                view(-37.5, 30);
            end
            
        end
        
        function [val, pval, valm, pvalm] = GetSatValues(this, spec, params, varargin)
            % [val, pval, valm, pvalm] = GetSatValues(this, spec, params) returns satisfaction values for spec computed
            % for parameters params. pval is a set of unique column vectors, and for each vector, val can have multiple values. 
            % pvalm can have repeated vectors. 
            
            spec_monitored = isfield(this.P, 'props');
            if spec_monitored
                if nargin >= 2
                    iprop = find(strcmp(get_id(spec), this.P.props_names));
                elseif nargin==1
                    iprop = 1:numel(this.P.props);
                end
                spec_monitored = ~isempty(iprop);
            else
                 val = [];
                pval = [];
            end
 
            if (~spec_monitored)||(isempty(iprop)) % spec not found, returns empty values
                 val = [];
                pval = [];
            else
                for ip =1:numel(iprop)
                    prop_values = this.P.props_values(iprop(ip),:);
                    vali  = cat(1, prop_values.val);
                    val(ip,:) = vali(:,1);
                end
            end
            
            if exist('params', 'var')
                pvalm = this.GetParam(params);
                valm = val;
                [pval, idxu, idx  ] = unique(pvalm', 'rows');
                val = nan(1, numel(idxu));
                for iu = 1:numel(idxu)
                    new_val = valm( idx==iu);
                    if numel(new_val)>size(val, 1)
                        val(end+1:numel(new_val),:) = NaN;
                    end
                    val(1:numel(new_val), iu) = new_val';
                end
            else
                pval = this.P.pts(this.P.DimX:end,:);
            end
            pval = pval';
            
        end
        
        function [out] = PlotRobustMap(this, phi, params, ranges, delta, options_in)
            % Plot robust satisfaction vs 1 or 2 parameters.
            
            % if zero argument, returns an option structure with defaults
            if nargin==1
                out = struct('contour', 1, 'style',[]);
                return
            end
            
            if nargout >=1
                out = gcf;
            end
            
            % no option, use defaults
            if ~exist('options_in','var')
                options_in = struct();
            end
            
            % option provided, make sure all fields are initialized
            options = this.PlotRobustMap();
            opt_in_fields = fieldnames(options_in);
            for  ifld=1:numel(opt_in_fields)
                options.(opt_in_fields{ifld}) = options_in.(opt_in_fields{ifld});
            end
            
            switch(nargin)
                case 2
                    if isempty(this.GetSatValues(phi))
                        this.CheckSpec(phi);
                    end
                    figure;
                    SplotProp(this.P, phi, options);
                    return;
                case 4
                    delta = 10;
            end
            
            if this.GetNbParamVectors()==1
                this.P = CreateParamSet(this.P, params, ranges);
                this.P = Refine(this.P, delta,1);
            end
            
            if isempty(this.GetSatValues(phi))
                this.Sim();
                this.CheckSpec(phi);
            end
            
            Pf = this.P;
            iparams = FindParam(this.P, params);
            Pf.dim = iparams;
            SplotProp(Pf, phi, options);
            
        end
        
        function [h, t, X]  = PlotExpr(this, stl_expr, varargin)
            % Plots a signal expression
            gca;
            if ~iscell(stl_expr)
                stl_expr = {stl_expr};
            end
            
            for i_exp = 1:numel(stl_expr)
                expr_tmp_ = STL_Formula('expr_tmp_', [stl_expr{i_exp} '> 0.']);
                [X, t] = STL_Eval(this.Sys, expr_tmp_, this.P, this.P.traj, this.P.traj{1}.time);
                if iscell(t)
                    for i_x = 1:numel(t)
                        h = plot(t{i_x},X{i_x}, varargin{:});
                    end
                else
                    h = plot(t,X, varargin{:});
                end
            end
        end
        
        function  [X, t]  = GetExprValues(this, stl_expr, varargin)
            % gets values for a signal expression
            
            if ~iscell(stl_expr)
                stl_expr = {stl_expr};
            end
            
            for i_exp = 1:numel(stl_expr)
                expr_tmp_ = STL_Formula('expr_tmp_', [stl_expr{i_exp} '> 0.']);
                [X, t] = STL_Eval(this.Sys, expr_tmp_, this.P, this.P.traj, this.P.traj{1}.time);
            end
        end
               
        
        %% Sensitivity analysis
        function [mu, mustar, sigma] = SensiSpec(this, phi, params, ranges, opt)
            % SensiSpec Sensitivity analysis of a formula to a set of parameters
            this.ResetParamSet();
            opt.tspan = this.Sys.tspan;
            opt.params = FindParam(this.Sys,params);
            opt.lbound = ranges(:,1)';
            opt.ubound = ranges(:,2)';
            opt.plot = 2;
            
            [mu, mustar, sigma, Pr]= SPropSensi(this.Sys, this.P, phi, opt);
            this.P=Pr;
        end
        
        function [monotonicity, Pr, EE] = ChecksMonotony(this, phi, params, ranges, opt)
            % ChecksMonotony performs a quick check to infer monotonicity of a formula wrt parameters
            opt.tspan = this.Sys.tspan;
            opt.params = FindParam(this.Sys,params);
            opt.lbound = ranges(:,1)';
            opt.ubound = ranges(:,2)';
            opt.plot = 0;
            P0 = Sselect(this.P,1);
            
            [~, ~, ~, Pr, EE]= SPropSensi(this.Sys, P0, phi, opt);
            monotonicity = all(EE'>=0)-all(EE'<=0); % 1 if all positive, -1 if all negative, 0 otherwise
        end
        
        %% Printing
        function PrintSpecs(this)
            disp('Specifications:')
            disp('--------------')
            keys = this.Specs.keys;
            for is = 1:numel(keys)
                prop_name = keys{is};
                fprintf('%s',prop_name);
                if isfield(this.P, 'props_names')
                    ip = strcmp(this.P.props_names, prop_name);
                    idx_prop = find(ip);
                    if idx_prop
                        val = cat(1, this.P.props_values(idx_prop,:).val);
                        fprintf(': %d/%d satisfied.', numel(find(val>=0)),numel(val));
                    end
                end
                fprintf('\n');
            end
            disp(' ');
        end
        
        function PrintAll(this)
            this.UpdateSignalRanges();
            this.PrintSignals();
            this.PrintParams();
            this.PrintSpecs();
        end
        
        function st = disp(this)
            if isfield(this.P, 'traj')
                nb_traj = numel(this.P.traj);
            else
                nb_traj = 0;
            end
            
            st = ['BreachSystem ' this.Sys.name '. It contains ' num2str(this.GetNbParamVectors()) ' samples and ' num2str(nb_traj) ' unique traces.'];
            
            if nargout ==0
                disp(st);
            end
        end
        
        %% GUI
        function new_phi  = AddSpecGUI(this)
            signals = this.Sys.ParamList(1:this.Sys.DimX);
            new_phi = STL_TemplateGUI('varargin', signals);
            if ~isempty(new_phi)
                if isa(new_phi, 'STL_Formula')
                    this.Specs(get_id(new_phi)) = new_phi;
                end
                
                % Add property params with default values if they're not
                % defined yet
                params_prop = get_params(new_phi);
                names_params_prop = fieldnames(params_prop)';
                params_not_found = [];
                if ~isempty(names_params_prop)
                    [~,  idx_status ] = FindParam(this.P, names_params_prop);
                    params_not_found = names_params_prop(idx_status==0);
                end
                if ~isempty(params_not_found)
                    this.SetParamSpec(params_not_found, cellfun(@(c) (params_prop.(c)), params_not_found));
                end
            end
        end
        
        function RunGUI(this)
            BreachGui(this);
        end
        
        function TrajGUI(this)
            args = struct('working_sets', struct,'working_sets_file_name',...
                '', 'Sys', this.Sys, 'TrajSet', this.P);
            specs = this.Specs.keys;
            args.properties = struct;
            for ispec = 1:numel(specs)
                args.properties.(specs{ispec}) = this.Specs(specs{ispec});
            end
            
            BreachTrajGui(this,args);
        end
        
        %% Experimental
        function report = Analysis(this)
            
            STL_ReadFile('stlib.stl');
            
            % Simple analysis
            % Checks zero signals
            req_zero = STL_Formula('phi', 'req_zero');
            report.res_zero = STL_EvalTemplate(this.Sys, req_zero, this.P, this.P.traj, {'x_'});
            sigs_left = [report.res_zero.some report.res_zero.none];
            
            if ~isempty(report.res_zero.all)
                fprintf('---------------------------------------------\n' )
                fprintf('The following signals were found to be zero: \n' )
                fprintf('---------------------------------------------\n' )
                disp(report.res_zero.all);
            end
            
            % Checks constant signals
            req_stable = STL_Formula('phi', 'req_stable');
            report.res_stable = STL_EvalTemplate(this.Sys, req_stable, this.P, this.P.traj, {'x_'}, sigs_left);
            if ~isempty(report.res_stable.all)
                fprintf('------------------------------------------------\n' )
                fprintf('The following signals were found to be constant: \n' )
                fprintf('------------------------------------------------\n' )
                disp(report.res_stable.all');
            end
            sigs_left = [report.res_stable.some report.res_stable.none];
            
            % Checks non-decreasing signals
            req_inc = STL_Formula('phi', 'req_inc');
            report.res_inc = STL_EvalTemplate(this.Sys, req_inc, this.P, this.P.traj, {'x_'}, sigs_left);
            if ~isempty(report.res_inc.all)
                fprintf('-----------------------------------------------------\n' )
                fprintf('The following signals were found to be non-decreasing: \n' )
                fprintf('-----------------------------------------------------\n' )
                disp(report.res_inc.all');
            end
            
            % Checks non-increasing signals
            req_dec = STL_Formula('phi', 'req_dec');
            report.res_dec = STL_EvalTemplate(this.Sys, req_dec, this.P, this.P.traj, {'x_'}, sigs_left);
            if ~isempty(report.res_dec.all)
                fprintf('-----------------------------------------------------\n' )
                fprintf('The following signals were found to be non-increasing: \n' )
                fprintf('-----------------------------------------------------\n' )
                disp(report.res_dec.all');
            end
            
            % Checks non-increasing signals
            req_dec = STL_Formula('phi', 'req_pwc');
            report.res_dec = STL_EvalTemplate(this.Sys, req_dec, this.P, this.P.traj, {'x_'}, sigs_left);
            if ~isempty(report.res_dec.all)
                fprintf('-------------------------------------------------------\n' )
                fprintf('The following signals were found to be piecewise stable: \n' )
                fprintf('-------------------------------------------------------\n' )
                disp(report.res_dec.all');
            end
            
            % Search for steps
            req_step = STL_Formula('phi', 'req_step');
            report.res_step = STL_EvalTemplate(this.Sys, req_step, this.P, this.P.traj, {'x_step_'}, sigs_left);
            if ~isempty(report.res_step.all)
                fprintf('---------------------------------------------\n' )
                fprintf('The following signals appear to feature steps: \n' )
                fprintf('---------------------------------------------\n' )
                disp(report.res_step.all');
                sigs_steps = report.res_step.all;
            end
            
            % Search for spikes
            req_spike = STL_Formula('phi', 'req_spike');
            report.res_spike = STL_EvalTemplate(this.Sys, req_spike, this.P, this.P.traj, {'x_'}, sigs_left);
            if ~isempty(report.res_spike.all)
                fprintf('---------------------------------------------------------\n' )
                fprintf('The following signals appear to feature spikes or valleys: \n' )
                fprintf('---------------------------------------------------------\n' )
                disp(report.res_spike.all');
                sigs_spikes = report.res_spike.all;
            end
            
            
            % Dual analysis
            % Correlation between steps and spikes
            if ~isempty(report.res_spike.all)
                
                req_steps_and_spikes = STL_Formula('phi', 'req_steps_and_spikes');
                report.res_steps_and_spikes = STL_EvalTemplate(this.Sys, req_steps_and_spikes, this.P, this.P.traj, {'x_step_','x_'}, {sigs_steps,sigs_spikes});
                if ~isempty(report.res_steps_and_spikes.all)
                    fprintf('---------------------------------------------------------------------\n' )
                    fprintf('The following pairs of signals appear to be correlated (step => spike): \n' )
                    fprintf('---------------------------------------------------------------------\n' )
                    for i_res= 1:numel(report.res_steps_and_spikes.all)
                        sigs = report.res_steps_and_spikes.all{i_res};
                        disp([ sigs{1} ',' sigs{2}]);
                    end
                end
            end
            
        end
        
    end
end
