clear;

InitBreach;

mdl = 'Autotrans_shift';
Br = MyBreachSimulinkSystem(mdl);


input_gen.type = 'UniStep';
input_gen.cp = 5;
%Br.SetInputGen(input_gen);

%for cpi = 0:input_gen.cp -1
%    Br.SetParamRanges();
%end

%phi = STL_Formula();


%ufp = UCB1Falsification(Br, phi);

%ufp.solve();

