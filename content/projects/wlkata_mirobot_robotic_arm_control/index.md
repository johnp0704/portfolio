---
title: "Wlkata Mirobot Robotic Arm Control"
end_date: 2026-03-15
draft: false
language: en
featured_image: "wlkata_hero_photo.png"
summary: "A ROS2 control stack for a physical 6-axis Wlkata Mirobot arm, built up from joint commands to an optimization-based inverse kinematics solver and pure pursuit tracking of paths the user draws."
description: "Autonomy II midterm project: ROS2 control of a Wlkata Mirobot 6-DOF arm, with an RViz2 GUI bridge, forward kinematics, a gradient-based (L-BFGS-B) inverse kinematics solver, and pure pursuit path tracking."
author: John Poirier
scope: Small
tags: [ROS2, Python, Robotic Manipulation, Autonomy]

# "At a glance" panel on the project page. Leave any of these out to hide that row.
context: "UVM Autonomy II Course"
role: "Lead on arm control, kinematics, and IK"
team: "2-person team"

# Source code: shown as a banner under the photo and a button in the sidebar
repo: "https://github.com/johnp0704/Wlkata-Mirobot-Robotic-Arm"
repo_note: "ROS2 nodes: joint commander, GUI bridge, IK solver, and pure pursuit"

# Extra buttons under the panel; entries with an empty url are hidden.
links:
  - label: "Watch the Demo"
    url: "#mirobot-demo"

# Report PDF in this folder. Shown as a viewer at the bottom.
report: "AutonomyII_Midterm_Project_Report_JP_SW.pdf"
report_label: "Project Report"

# Only publish bundle files the page actually uses (keeps the full 10-minute video report private)
build:
  publishResources: false
---

## Overview

A ROS2 control system for a **physical Wlkata Mirobot**, a desktop 6-axis robotic arm, built up one layer at a time: sending raw joint angles, driving the real arm from **RViz2's joint sliders** with live **forward kinematics**, solving **inverse kinematics** with gradient-based optimization so the arm can be commanded in Cartesian coordinates, and finally **pure pursuit**, where the arm's end effector autonomously follows a path the user draws on screen. RViz2 mirrored the real arm at every stage.

{{< video src="Mirobot_Demo_Reel.mp4" poster="Mirobot_Demo_Reel_poster.jpg" id="mirobot-demo" caption="The project step by step: the homing sequence, driving the arm from the RViz2 GUI, the inverse kinematics solver running a Cartesian test sequence, and pure pursuit tracking a user-drawn path." >}}

## The Challenge

Commanding a robot arm by its joint angles is easy; commanding it to put its tool *somewhere* is not. Going from a target position and orientation to six joint angles has no simple closed-form answer for a general arm, so the solution has to respect joint limits, avoid awkward configurations, and stay fast enough to update continuously while the arm tracks a path. All of it also had to run as cooperating ROS2 nodes talking to real hardware over a serial connection through WSL, where a mislabeled topic fails silently instead of throwing an error.

## My Role & Scope of Work

This was a two-person project. I built the first four stages of the control stack, and helped with the fifth:

- **Hardware bring-up:** established the serial connection to the arm through WSL and set up the ROS2 workspace and launch file.
- **Joint commander:** the node that publishes joint-angle sequences to the arm's driver.
- **GUI bridge and forward kinematics:** connected RViz2's joint sliders to the physical arm and computed the end-effector pose from the URDF model.
- **Inverse kinematics solver:** designed the weighted objective function and the L-BFGS-B optimization loop with joint limits, plus the Cartesian sender node used to test it.
- **Pure pursuit (supporting):** helped my teammate, who led this stage, build and tune the path-tracking node.

## System Design

The system is a chain of ROS2 nodes around the arm's provided driver, which takes joint-angle commands over serial. Each stage added a new way of generating those commands.

### Joint Commands and the GUI Bridge

The first node sends sequences of joint angles straight to the driver, verifying the hardware connection and the arm's motion. The **GUI bridge** node then connects RViz2's joint-state sliders to the real arm: it subscribes to the GUI's joint states on a separate topic (to avoid conflicting with the real robot's), republishes them as driver commands, and runs **forward kinematics** with the `ikpy` library on the robot's URDF model to report the end effector's position (X, Y, Z) and orientation (roll, pitch, yaw) in real time.

### Inverse Kinematics Solver

The IK node subscribes to Cartesian targets (position in mm, orientation in degrees) and solves for the six joint angles by **optimization**:

- **Objective function:** runs forward kinematics for a candidate set of joint angles and measures how far the end effector is from the target: the norm of the position error plus the norm of the rotation-matrix error.
- **Weighting:** position error is weighted 100 and rotation error 2, so the solver prioritizes getting the tool to the right place. We used this **additive** form instead of the multiplicative one the project document suggested: multiplying the terms could make a large position error look small whenever the rotation error was near zero.
- **Optimizer:** SciPy's **L-BFGS-B**, a gradient-based method that handles bounds, with the **joint limits** from the URDF as constraints, so every solution is physically reachable.
- **Seeding:** each solve starts from the arm's last joint angles, and the initial seed bends the shoulder and elbow slightly to steer clear of singularities on the first move.

A **Cartesian sender** node exercised the solver with a test sequence stepping the tool along each axis.

![RViz2 and the physical arm running the inverse kinematics solver](Mirobot_IK_Result.jpg "The IK solver in action: the RViz2 model (left) and the physical arm (top right) reaching the same Cartesian target, with the solver's output in the terminal.")

### Pure Pursuit Path Tracking

The final node lets the user **draw a path** in a GUI, then has the arm's tool follow it, using the IK solver underneath. It runs in two phases:

1. **Approach:** move the tool to the path's start point, shown as a target marker in RViz2.
2. **Pursuit:** each tick, find the path point closest to the tool (searching a window ahead of the last target), then step forward to a **look-ahead point** 5 cm away and command the arm there. A **maximum jump** of 10 path points per tick and a **lag check** stop the target from racing ahead of the arm, a GUI speed setting controls how often the target advances, and the run ends once the tool is within 50 mm of the final point.

![RViz2, the physical arm, and the path-drawing GUI during pure pursuit](Mirobot_Pure_Pursuit_Result.jpg "Pure pursuit: the physical arm (top left), the RViz2 model following the target (center), and the path-drawing GUI (right).")

## Key Methods & Tools

| Method / Tool | Used for |
| --- | --- |
| **ROS2** (Python, `rclpy`) | Nodes, topics, and launch files around the arm's driver |
| **RViz2** and URDF | Live visualization mirroring the physical arm |
| **ikpy** | Forward kinematics from the robot's URDF model |
| **SciPy L-BFGS-B** | Bounded, gradient-based inverse kinematics |
| **Pure pursuit** | Look-ahead path tracking for the end effector |
| **Wlkata Mirobot** (6-DOF) | Physical robot arm, controlled over serial via WSL |

## Results

Every stage worked on the physical arm: joint sequences, slider control with live forward kinematics, Cartesian commands through the IK solver, and pure pursuit tracking of hand-drawn paths, with RViz2 matching the real arm throughout.

## Challenges & Lessons Learned

- **Topic names fail silently.** A mismatched topic name doesn't throw an error; nodes just never hear each other. Careful, consistent naming (and checking the topic graph) mattered more than any single line of code.
- **Design the objective, don't just copy it.** The suggested multiplicative IK cost could report a tiny error for a pose that was badly out of position. Switching to a weighted sum made the solver behave predictably.
- **Open-loop hardware needs workarounds.** The arm has no joint encoders, so at startup the node had no real position to report and published zeros. Raising the start-point approach threshold from 20 mm to 200 mm let pursuit begin anyway, at the cost of possibly jumping into the middle of a path if the arm starts far away.
- **Tuning is a trade-off.** Increasing the look-ahead distance from 2.5 cm to 5 cm smoothed out jitter from imperfect hand-drawn paths, but made the arm cut sharp corners. The right setting depends on which behavior matters more.
