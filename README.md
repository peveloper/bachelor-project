# Terrain traversability prediction by a robot

## Introduction

The project aims to use Machine Learning in order for a robot to predict whether it can traverse a given terrain or not. The dataset passed to the Neural Network will be the result of several simulations in VREP, an open-source virtual robot experimentation platform.

## Motivation and Goal

Unmanned vehicle navigation and terrain traversability is a core issue in robotics and in its consequent applications such as land exploration, military scouting or reconnaissance and more general situations, thus the need for an intelligent system, that can guarantee a **wheeled** robot to estimate with accuracy if a given terrain patch is traversable.

## Project Tasks

There are two main phases in the project:

- The goal of this phase consists in writing a controller for the simulated robot and building a dataset of terrain labels that the robot has either traversed or not.
- The goal of this phase is to build a classifier (such as a Neural Network) to predict the traversability of a given terrain patch.

### Writing the controller and building a Dataset

The very first task is write a controller for the simulated robot (in such a way that the robot follow a predetermined path), and analyze what happened during the simulation (the robot got stuck or capsized). In order to obtain an acceptable final result a key component such as the dataset must be construct. For this application the dataset will consist of a collection of thousands hundreds of patch label obtained by several simulations with V-REP.

### Building a 3d terrain

In order to simulate an off road environment and guarantee a large dataset of possible terrain configurations that the robot will face, a large dataset of heightmaps will be built. The process of generating a 3d terrain in a procedu- ral way is based on the [Perlin Noise](https://en.wikipedia.org/wiki/Perlin_noise#Algorithm_detail) algorithm.

### Building a classifier

After collecting the results from the simulations, the final task is to analyze the dataset with the supervisors and investigate options to apply machine learning to automatically estimate whether a given area is traversable or not.
