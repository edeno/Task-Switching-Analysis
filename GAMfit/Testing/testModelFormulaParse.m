% Test cases for modelFormulaParse
str{1} = 'Rule';
str{2} = 'Rule + Response Direction';
str{3} = 'Rule * Response Direction';
str{4} = 's(Rule, Trial Time) + s(Response Direction, Trial Time)';
str{5} = 's(Rule * Response Direction, Trial Time)';
str{6} = 's(Switch Distance)';
str{7} = 's(Rule, Trial Time, basis_dim = 5)';
str{8} = 's(Rule, Trial Time, basis_degree = 1)';
str{9} = 's(Rule, Trial Time, penalty_degree = 0)';
str{10} = 's(Rule, Trial Time, ridgeLambda = 0)';
str{11} = 's(Rule, Trial Time, knots = [0; 10; 30])';
str{12} = 's(Rule, Trial Time) + Response Direction';
%
model = cellfun(@modelFormulaParse, str, 'UniformOutput', false);
% Model 1
assert(isequal(model{1}.terms, {'Rule'}));
assert(isequal(model{1}.isSmooth, false));
assert(isequal(model{1}.smoothParams_opt, {[]}));
assert(isequal(model{1}.smoothingTerm, {[]}));
assert(isequal(model{1}.isInteraction, false));
% Model 2
assert(isequal(model{2}.terms, {'Rule'; 'Response Direction'}))
assert(isequal(model{2}.isSmooth, false(2,1)));
assert(isequal(model{2}.smoothParams_opt, {[]; []}));
assert(isequal(model{2}.smoothingTerm, {[]; []}));
assert(isequal(model{2}.isInteraction, false(2,1)));
% Model 3
assert(isequal(model{3}.terms, {'Rule'; 'Response Direction'; 'Rule:Response Direction'}))
assert(isequal(model{3}.isSmooth, false(3,1)));
assert(isequal(model{3}.smoothParams_opt, {[]; []; []}));
assert(isequal(model{3}.smoothingTerm, {[]; []; []}));
assert(isequal(model{3}.isInteraction, [false(2,1); true]));
% Model 4
assert(isequal(model{4}.terms, {'Rule'; 'Response Direction'}))
assert(isequal(model{4}.isSmooth, true(2,1)));
assert(isequal(model{4}.smoothParams_opt, {[]; []}));
assert(isequal(model{4}.smoothingTerm, {'Trial Time'; 'Trial Time'}));
assert(isequal(model{4}.isInteraction, false(2,1)));
% Model 5
assert(isequal(model{5}.terms, {'Rule'; 'Response Direction'; 'Rule:Response Direction'}))
assert(isequal(model{5}.isSmooth, true(3,1)));
assert(isequal(model{5}.smoothParams_opt, {[]; []; []}));
assert(isequal(model{5}.smoothingTerm, {'Trial Time'; 'Trial Time';
    'Trial Time'}));
assert(isequal(model{5}.isInteraction, [false(2,1); true]));
% Model 6
assert(isequal(model{6}.terms, {'Switch Distance'}));
assert(isequal(model{6}.isSmooth, true));
assert(isequal(model{6}.smoothParams_opt, {[]}));
assert(isequal(model{6}.smoothingTerm, {'Switch Distance'}));
assert(isequal(model{6}.isInteraction, false));
% Model 7
assert(isequal(model{7}.terms, {'Rule'}));
assert(isequal(model{7}.isSmooth, true));
assert(isequal(model{7}.smoothParams_opt, {{'basis_dim', 5}}));
assert(isequal(model{7}.smoothingTerm, {'Trial Time'}));
assert(isequal(model{7}.isInteraction, false));
% Model 8
assert(isequal(model{8}.terms, {'Rule'}));
assert(isequal(model{8}.isSmooth, true));
assert(isequal(model{8}.smoothParams_opt, {{'basis_degree', 1}}));
assert(isequal(model{8}.smoothingTerm, {'Trial Time'}));
assert(isequal(model{8}.isInteraction, false));
% Model 9
assert(isequal(model{9}.terms, {'Rule'}));
assert(isequal(model{9}.isSmooth, true));
assert(isequal(model{9}.smoothParams_opt, {{'penalty_degree', 0}}));
assert(isequal(model{9}.smoothingTerm, {'Trial Time'}));
assert(isequal(model{9}.isInteraction, false));
% Model 10
assert(isequal(model{10}.terms, {'Rule'}));
assert(isequal(model{10}.isSmooth, true));
assert(isequal(model{10}.smoothParams_opt, {{'ridgeLambda', 0}}));
assert(isequal(model{10}.smoothingTerm, {'Trial Time'}));
assert(isequal(model{10}.isInteraction, false));
% Model 11
assert(isequal(model{11}.terms, {'Rule'}));
assert(isequal(model{11}.isSmooth, true));
assert(isequal(model{11}.smoothParams_opt, {{'knots', [0; 10; 30]}}));
assert(isequal(model{11}.smoothingTerm, {'Trial Time'}));
assert(isequal(model{11}.isInteraction, false));
% Model 12
assert(isequal(model{12}.terms, {'Rule'; 'Response Direction'}))
assert(isequal(model{12}.isSmooth, [true; false]));
assert(isequal(model{12}.smoothParams_opt, {[]; []}));
assert(isequal(model{12}.smoothingTerm, {'Trial Time'; []}));
assert(isequal(model{12}.isInteraction, false(2,1)));