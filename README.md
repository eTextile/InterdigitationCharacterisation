# Strip Pattern Generator

## What?

This repo is used to characterize different sensor patterns.
Here is an illustration of what is simulated:
![animation](animation.gif)

- The white circles represent a simulated finger pressure
- The histogram represents the simulated raw data
- The grey circles represent a retrieval attempt of the finger position from this data

Here is a complete sensor characterization example:
![characterization](characterization.png)
- The black plot shows the error in the position retrieval attempt
- The white circles are just here as reference (to show the finger size)

## How?

To run the .pde program, it just needs the [Processing IDE](https://processing.org/download/)
You can edit the 1st variables to get your custom patterns.

## Note

This project started to generate patterns to etch conductive fabrics that are used in the [eTextile matrix sensor project](http://eTextile.org).
The etching process have been chosen to explore complex matrix design in order to experiment a new analog interpolation technique.
The etching tutorial can be found on the [DataPaulette eTextile hackerspace wiki](http://wiki.datapaulette.org/doku.php/atelier/documentation/materiautheque/materiaux/electronique_textile/connectique/circuits_souples)

