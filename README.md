#Overview
A *Mathematica* (*Wolfram Language*) package for plotting phase portraits of autonomous two-dimensional dynamical systems.

Created by [Calle Ekdahl](https://github.com/cekdahl).

GPL-2.0+ licensed.

Current version: 1.0

This package is based on algorithms described in *Practical Numerical Algorithms for Chaotic Systems*, by T.S. Parker and L.O. Chua (1989). Chapter 10 is particularly relevant.

# Installation
Download the latest version of the package from the *releases* tab here on Github. Drop *PhasePortrait.m* into
    
    SystemOpen@FileNameJoin[{$UserBaseDirectory, "Applications"}]

and then load the package using

    << PhasePortrait`

# Example usage

    PhasePortrait[{
      x'[t] == -y[t],
      y'[t] == -Sin[x[t]]
      }, {x, y}, t, {{-2 Pi, -4}, {2 Pi, 4.3}},
     PortraitDensity -> 12
     ]

![Pendulum phase portrait](https://github.com/cekdahl/PhasePortrait/blob/master/assets/phaseportrait_ex1.png?raw=true)

    PhasePortrait[{
      x'[t] == -x[t],
      y'[t] == x[t] + y[t]
      }, {x, y}, t, {{-5, -5}, {5, 5}},
     PortraitDensity -> 16
     ]

![Linear system phase portrait](https://github.com/cekdahl/PhasePortrait/blob/master/assets/phaseportrait_ex2.png?raw=true)

# Options
*PhasePortrait\`* can be controlled through several options that are listed here below. It can also be given any options that can be given to `ParametricPlot`, such as `PlotTheme` or `Epilog`.

## PortraitDensity
`PortraitDensity` determines the density of the phase portrait. A lower number gives a more sparse phase portrait. To understand what exactly `PortraitDensity` is, it helps to know how the algorithm that picks trajectories works. It starts by dividing up the area into cells, which are marked "empty". When a trajectory passes through a cell it is marked as "occupied". Trajectories are added to the phase portrait one by one; when the next trajectory is selected it cannot start in an occupied cell. When all cells are occupied the algorithm is done.

![A trajectory and the cells that it passes through.](https://github.com/cekdahl/PhasePortrait/blob/master/assets/phaseportrait_ex3.png?raw=true)

`PortraitDensity` is the number of cells along the shortest end of the plot. If the aspect ratio of the plot is one, there are exactly `PortraitDensity` number of cells along each direction.

## PortraitBoundsTolerance
If a trajectory leaves the predefined area the integrator will stop that trajectory at that point. However, sometimes trajectories could leave the area and then come back after a while if integration would be continued. `PortraitBoundsTolerance` is a multiplier that increases the size of the area of that trajectories are allowed to travel in without having an effect on the displayed area. For example, if `PortraitBoundsTolerance` is 1.5 and the area is the square `{{0,0}, {10,10}}`, then the area that trajectories are allowed to travel within without being stopped is `{{-2.5, -2.5}, {12.5, 12.5}}`.

Note that trajectories can also be terminated for other reasons. If they are too long - particularly if they enter a limit cycle - they will be stopped, and also if they approach equilibrium points. See also the section on tolerances for more information about this.

## CellOrdering
Because the starting points of trajectories are selected from empty cells, as described in the section about `PortraitDensity`, it matters in which order cells are selected. `CellOrdering` determines how starting points are selected by determining which cells should be tried first, occupied cells are simple skipped over. The images below show how the different available orderings behave, lower numbers indicating cells with the higher priority. All examples show a 5x5 grid, but these orderings can be applied to grids of arbitrary dimensions.

### Clockwise

    CellOrdering -> "Clockwise"

![Clockwise cell ordering](https://github.com/cekdahl/PhasePortrait/blob/master/assets/phaseportrait_ex5.png?raw=true)

This is sometimes called a "spiral matrix".

### Random

    CellOrdering -> "Random"

![Random cell ordering](https://github.com/cekdahl/PhasePortrait/blob/master/assets/phaseportrait_ex6.png?raw=true)

(For example.)

### OddSymmetric

    CellOrdering -> "OddSymmetric"

![Odd symmetric cell ordering.](https://github.com/cekdahl/PhasePortrait/blob/master/assets/phaseportrait_ex4.png?raw=true)

Meant to be used with dynamical systems that have odd symmetric solutions.

## InitialValues
It is possible to manually provide starting points for trajectories using the option `InitialValues`. These starting points will be prioritized over all other starting points. The option `GenerateInitialValues` can be used to draw only the manually specified trajectories.

    PhasePortrait[{
      x'[t] == -x[t],
      y'[t] == x[t] + y[t]
      }, {x, y}, t, {{-5, -5}, {5, 5}},
     InitialValues -> {{-2, 0}, {2, 0}},
     GenerateInitialValues -> False
     ]

![Manually specified starting points.](https://github.com/cekdahl/PhasePortrait/blob/master/assets/phaseportrait_ex7.png?raw=true)

## Tolerances
As mentioned in the section on `PortraitBoundsTolerance` there are a couple of things that can stop a trajectory. One is if it travels outside of the given area, another is if it grows too long. A third reason for stopping a trajectory is if it approaches an equilibrium - it will keep going closer and closer as time wears on but it does not affect the visualization of it. In order to save time, it is better to stop integrating. Let delta be the distance between the current position and the previous position, and let the current position be p. If delta < Er*p+Ea then the trajectory is considered to have reached equilibrium, where Er is the relative tolerance and Ea is the absolute tolerance. By default both Er and Ea are 10^-6, but if this needs to be changed for whatever reason it can be changed using the options `RelativeTolerance` and `AbsoluteTolerance`.