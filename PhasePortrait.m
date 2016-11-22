(* Mathematica Package                     *)
(* Created by IntelliJ IDEA                *)

(* :Title: PhasePortrait                   *)
(* :Context: PhasePortrait`                *)
(* :Author: Calle Ekdahl                   *)
(* :Date: 2015-12-30                       *)

(* :Package Version: 1.0.1                 *)
(* :Mathematica Version: 10.3              *)
(* :Copyright: (c) 2015 Calle Ekdahl       *)
(* :Keywords:                              *)
(* :Discussion:                            *)

BeginPackage["PhasePortrait`"]
PhasePortrait::usage = "PhasePortrait[eqns, {x, y}, t, {{xmin, ymin}, {xmax, ymax}}] plots a phase portrait corresponding\
 to the ordinary differential equations eqns for the functions x and y with the independent variable t, within the range\
  given by xmin, xmax, ymin and ymax.";

PortraitDensity;
PortraitBoundsTolerance;
PortraitGrid;
InitialValues;
GenerateInitialValues;
AbsoluteTolerance;
RelativeTolerance;

Begin["Private`"] (* Begin Private Context *)

Options[PhasePortrait] = Join[Options[ParametricPlot], {
  PortraitDensity -> 20,
  PortraitBoundsTolerance -> 1,
  PortraitGrid -> "Clockwise",
  InitialValues -> {},
  GenerateInitialValues -> True,
  AbsoluteTolerance -> 10^-6,
  RelativeTolerance -> 10^-6
}];

SyntaxInformation[PhasePortrait] = {
  "ArgumentsPattern" -> {_, {_,_}, _, {{_, _}, {_, _}}, OptionsPattern[]},
  "LocalVariables" -> {"Solve", {1,3}}
}

PhasePortrait[system_, u_, t_, {{xmin_, ymin_}, {xmax_, ymax_}},opts: OptionsPattern[]] := Module[
  {grid, aspectRatio, initialConditions, boundary, phasePortraitObject, initialIndices, initialCoordinates, userInitialIndices},
  aspectRatio = {ymax - ymin, xmax - xmin}/Min[ymax - ymin, xmax - xmin] // Floor;
  grid = ConstantArray[0, OptionValue[PortraitDensity] aspectRatio];

  initialIndices = Switch[OptionValue[PortraitGrid],
    "Random", RandomCellOrdering@Dimensions[grid],
    "Clockwise", ClockwiseCellOrdering@Dimensions[grid],
    "OddSymmetric", OddSymmetricCellOrdering@Dimensions[grid],
    _, ClockwiseCellOrdering@Dimensions[grid]
  ];
  initialCoordinates = IndicesToCoordinates[{{xmin, ymin}, {xmax, ymax}}, Dimensions@grid] /@ initialIndices;
  initialConditions = Transpose[{initialIndices, initialCoordinates}];

  userInitialIndices = CoordinatesToIndices[{{xmin, ymin}, {xmax, ymax}}, Dimensions@grid] /@ OptionValue[InitialValues];

  If[OptionValue[GenerateInitialValues],
    initialConditions = Join[Transpose[{userInitialIndices, OptionValue[InitialValues]}], initialConditions],
    initialConditions = Transpose[{userInitialIndices, OptionValue[InitialValues]}]
  ];

  boundary = {{
    (xmin + xmax)/2 - OptionValue[PortraitBoundsTolerance] (xmax - xmin)/2,
    (ymin + ymax)/2 - OptionValue[PortraitBoundsTolerance] (ymax - ymin)/2
  }, {
    (xmin + xmax)/2 + OptionValue[PortraitBoundsTolerance] (xmax - xmin)/2,
    (ymin + ymax)/2 + OptionValue[PortraitBoundsTolerance] (ymax - ymin)/2}
  };

  phasePortraitObject = Fold[
    AddTrajectory[system, u, t, boundary, {OptionValue[RelativeTolerance], OptionValue[AbsoluteTolerance]}],
    PhasePortraitState[grid, {}],
    initialConditions
  ];

  DrawPhasePortrait[
    phasePortraitObject,
    PlotRange -> {{xmin, xmax},{ymin, ymax}},
    Sequence@@FilterRules[{opts},Options[ParametricPlot]]
  ]
]

DrawPhasePortrait[PhasePortraitState[grid_, solutions_], opts___] := Show[DrawTrajectory[opts] /@ solutions]

DrawTrajectory[opts___][{x_, y_}] := Module[{grid},
  grid = Flatten@x["Grid"];
  ParametricPlot[{x[t], y[t]}, {t, First[grid], Last[grid]}, opts]
]

AddTrajectory[system_, {x_, y_}, t_, {{xmin_, ymin_}, {xmax_, ymax_}}, {reltol_, abstol_}][
  PhasePortraitState[grid_, solutions_], {{Ix_, Iy_}, {x0_, y0_}}] := Module[
  {forwards, backwards, newGrid, newSolutions},
  If[
    grid[[Ix, Iy]] == 1,
    Return[PhasePortraitState[grid, solutions]]
  ];

  forwards = TrajectoryForwards[system, {x, y}, t, {{xmin, ymin}, {xmax, ymax}}, {x0, y0}, {reltol, abstol}];
  backwards = TrajectoryBackwards[system, {x, y}, t, {{xmin, ymin}, {xmax, ymax}}, {x0, y0}, {reltol, abstol}];

  newSolutions = Join[{forwards, backwards}, solutions];

  newGrid = UpdateGrid[grid, {{xmin, ymin}, {xmax, ymax}}, forwards];
  newGrid = UpdateGrid[newGrid, {{xmin, ymin}, {xmax, ymax}}, backwards];

  PhasePortraitState[newGrid, newSolutions]
]

TrajectoryForwards[args__] := Trajectory[args, Infinity]
TrajectoryBackwards[args__] := Trajectory[args, -Infinity]
Trajectory[eqns_, {x_,y_}, t_, {{xmin_,ymin_}, {xmax_,ymax_}}, {x0_,y0_}, {reltol_, abstol_}, tmax_] := Module[
  {system, sol, oldstep = {x0, y0}, convergent = False, arcLength = 0},
  system = Join[eqns, {
    x[0] == x0,
    y[0] == y0,
    WhenEvent[
      x[t] < xmin || y[t] < ymin || x[t] > xmax || y[t] > ymax || convergent || (arcLength > 2 (xmax - xmin + ymax - ymin)),
      "StopIntegration",
      "LocationMethod" -> "StepEnd"
    ]
  }];

  sol = NDSolve[system, {x, y}, {t, 0, tmax}, StepMonitor :> (
      arcLength += Norm[{x[t], y[t]} - oldstep];
      convergent = reltol Norm[{x[t],y[t]}] + abstol;
      convergent = Norm[{x[t], y[t]} - oldstep] < convergent;
      oldstep = {x[t], y[t]};
    )];

  Head /@ First[{x[t], y[t]} /. sol]
]

UpdateGrid[grid_, {{xmin_, ymin_}, {xmax_, ymax_}}, {x_, y_}] := Module[
  {tmin, tmax, delta, nrOfSquares, n = 4, samples},
  {tmin, tmax} = {Min[#], Max[#]}&[x["Grid"]];
  nrOfSquares[0] = 0;
  nrOfSquares[1] = 0.5;
  While[nrOfSquares[0] < nrOfSquares[1],
    samples = {x[#], y[#]} & /@ Range[tmin, tmax, (tmax - tmin)/2^n];
    samples = CoordinatesToIndices[{{xmin, ymin}, {xmax, ymax}}, Dimensions@grid] /@ samples;
    samples = DeleteDuplicates[samples];
    nrOfSquares[0] = nrOfSquares[1];
    nrOfSquares[1] = Length[samples];
    n++;
  ];

  ReplacePart[grid, samples -> 1]
]

CoordinatesToIndices[{{xmin_, ymin_}, {xmax_, ymax_}}, {m_, n_}][{x_, y_}] := {
  Max[Ceiling[n (x - xmin)/(xmax - xmin)], 1],
  Max[Ceiling[m (y - ymin)/(ymax - ymin)], 1]
}
IndicesToCoordinates[{{xmin_, ymin_}, {xmax_, ymax_}}, {m_, n_}][{Ix_, Iy_}] := {
  Max[xmin+0.5, xmin+(xmax - xmin) (Ix-0.5)/n],
  Max[ymin+0.5, ymin+(ymax - ymin) (Iy-0.5)/m]
}

RandomCellOrdering[{xdim_, ydim_}] := RandomSample@Flatten[Table[{i, j},{i, ydim},{j, xdim}],1]
OddSymmetricCellOrdering[{xdim_, ydim_}] := Module[{indices, new},
  indices = Flatten[Table[{i, j}, {i, ydim}, {j, xdim}], 1];
  new = Riffle[indices, {ydim - # + 1, xdim - #2 + 1} & @@@ indices];
  new[[;; Length[new]/2]]
]
ClockwiseCellOrdering[{xdim_, ydim_}] := Module[{next, state, res},
  next[state[{x_, y_},{dx_, dy_},{edgex_, edgey_}, step_, turn_]] := state[{x+dx, y+dy}, {dx, dy}, {edgex, edgey}, step+1, turn];
  state[{x_, y_}, {dx_, dy_}, {edgex_, edgey_}, edgex_ | edgey_, 0] := state[{x, y}, {-dy, dx}, {edgex, edgey}, 1, 1];
  state[{x_, y_}, {dx_, 0}, {edgex_, edgey_}, edgex_, turn_ /; turn >= 1] := state[{x, y},{0, dx}, {edgex-1, edgey}, 1, turn+1];
  state[{x_, y_}, {0, dy_}, {edgex_, edgey_}, edgey_, turn_ /; turn >= 1] := state[{x,y}, {-dy,0}, {edgex,edgey-1}, 1, turn+1];

  res = NestList[next, state[{1,1}, {1,0},{xdim,ydim},1,0], xdim ydim-1];

  res /. state[{x_, y_}, __] :> {y ,x}
]

End[] (* End Private Context *)

EndPackage[]
